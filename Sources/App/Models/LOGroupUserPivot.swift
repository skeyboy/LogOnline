//
//  LOGroupUserPivot.swift
//  LogOnline
//
//  Created by sk on 2018/11/20.
//

import Foundation
import Vapor
import FluentMySQL
import MySQL

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
    var groups: Siblings<LOUser,LOGroup,LOGroupUserPivot>{
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
