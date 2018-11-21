//
//  LOuserDevicePivot.swift
//  LogOnline
//
//  Created by sk on 2018/11/19.
//

import Foundation
import Vapor
import FluentMySQL
import MySQL

struct LOUserDevicePivot: MySQLPivot {
    
  
    static var leftIDKey: WritableKeyPath<LOUserDevicePivot, Int> = \.userId
    
    static var rightIDKey: WritableKeyPath<LOUserDevicePivot, Int> = \.deviceId

    
    typealias Left = LOUser
    
    typealias Right = LODevice
    
    var id: Int?
    var userId: Int
    var deviceId: Int
    init(userId uId: Int, deviceId dId: Int) {
        self.userId = uId
        self.deviceId = dId
    }
}
extension LOUserDevicePivot: MySQLMigration{}
extension LOUserDevicePivot: Content{}
extension LOUserDevicePivot: ModifiablePivot{
    init(_ left: LOUser, _ right: LODevice) throws {
        userId = try left.requireID()
        deviceId = try right.requireID()
    }
}
extension LOUserDevicePivot{
    var logs: Children<LOUserDevicePivot, LOLog>{
        return children(\LOLog.uDevicePivotId)
    }
}
