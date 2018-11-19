//
//  LOGroup.swift
//  LogOnline
//
//  Created by sk on 2018/11/19.
//

import Foundation
import Vapor
import FluentMySQL
import MySQL

struct LOGroup: MySQLModel {
    var id: Int?
    var name: String
    //推荐添加bundle,默认使用时间戳
    var bundle: String?
    var idetifier: String?
    var createTime: TimeInterval?
    init(name nickName: String, bundle: String? = "\(Date().timeIntervalSince1970)" ) {
        self.name = nickName
        self.idetifier = "\(Date().timeIntervalSince1970)"
        createTime = Date().timeIntervalSince1970
    }
}


extension LOGroup: MySQLMigration{}
extension LOGroup: Content{}

struct LOGroupUserPivot: MySQLPivot{
    static var leftIDKey: WritableKeyPath<LOGroupUserPivot, Int> = \.userId
    
    static var rightIDKey: WritableKeyPath<LOGroupUserPivot, Int> = \.groupId
    
    typealias Left = LOUser
    
    typealias Right = LOGroup
    
    
    var id: Int?
    var userId: Int
    var groupId: Int
    init(user userId: Int, group groupId: Int) {
        self.userId = userId
        self.groupId = groupId
    }
}
extension LOGroup{
    var users: Siblings<LOGroup,LOUser,LOGroupUserPivot>{
        return siblings()
    }
}
extension LOUser{
    var users: Siblings<LOUser,LOGroup,LOGroupUserPivot>{
        return siblings()
    }
}
extension LOGroupUserPivot: ModifiablePivot{
    init(_ left: LOUser, _ right: LOGroup) throws {
        userId = try left.requireID()
        groupId = try right.requireID()
    }
}
extension LOGroupUserPivot: MySQLMigration{}
extension LOGroupUserPivot: Content{}
