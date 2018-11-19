//
//  LOLog.swift
//  LogOnline
//
//  Created by sk on 2018/11/19.
//

import Foundation
import Vapor
import FluentMySQL
import MySQL

struct LOLog: MySQLModel {
    var id: Int?
    
    /// 用户 和 device的映射
    var uDevicePivotId: Int
    var groupId: Int
    
    var query: String
    var responseBody: String
    init( groupId: Int, uDevicePivotId: Int, query: String, responseBody: String) {
         self.groupId = groupId
        self.uDevicePivotId = uDevicePivotId
        self.query = query
        self.responseBody = responseBody
    }
}
extension LOLog{
    var uDevicePivot:Parent<LOLog, LOUserDevicePivot>{
    return parent(\.uDevicePivotId)
    }
    public static var defaultContentType: MediaType {
        return MediaType.formData
    }
}
 
extension LOLog: MySQLMigration{}
extension LOLog: Content{}
