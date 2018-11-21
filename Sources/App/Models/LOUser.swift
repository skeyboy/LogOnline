//
//  LOUser.swift
//  LogOnline
//
//  Created by sk on 2018/11/19.
//

import Foundation
import Vapor
import FluentMySQL
import MySQL

 
struct LOUser: MySQLModel {
    var id: Int?
    
    // 当前登陆人标志
    var identifier: String
    init(identifier: String) {
        self.identifier = identifier
    }
}
 
extension LOUser: MySQLMigration{}
extension LOUser: Content{}




func login(req: Request)-> EventLoopFuture<LOUser>{
    struct LoginRequest: Content {
        //用户的个人信息综合字符串作为标志
        var userIdentifier: String
        var groupName: String
        var groupIdetifier: String
    }
    
    let loginRequest: LoginRequest =   try! req.query.decode(LoginRequest.self)
    return  LOGroup.query(on: req)
        .filter(\.idetifier, .equal, loginRequest.groupIdetifier)
        .filter(\.name, .equal, loginRequest.groupName)
        .first().flatMap({ (group:LOGroup?) -> EventLoopFuture<LOUser> in
            
            return  LOUser.query(on: req)
                .filter(\.identifier, .equal, loginRequest.userIdentifier)
                .first()
                .flatMap({ (user:LOUser?) -> EventLoopFuture<LOUser> in
                    if user == nil {
                        return LOUser.init(identifier: loginRequest.userIdentifier).create(on: req)
                    }else{
                        let result = req.eventLoop.newPromise(LOUser.self)
                        result.succeed(result: user!)
                        return result.futureResult
                    }
                }).flatMap({ (user:LOUser) -> EventLoopFuture<LOUser> in
                    try req.authenticateSession(user)
                    // 用户第一注册成功之后绑定
                    return try LOGroupUserPivot.init(user, group!).create(on: req).flatMap({ (pivot:LOGroupUserPivot) -> EventLoopFuture<LOUser> in
                        let result = req.eventLoop.newPromise(LOUser.self)
                        result.succeed(result: user)
                        return result.futureResult
                    })
                    
                    
                })
            
        })
}
    
