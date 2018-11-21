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
    var shorURL: String
    var query: String
    var responseBody:Data
    
    init( groupId: Int, uDevicePivotId: Int, shorURL: String, query: String, responseBody: String) {
         self.groupId = groupId
        self.uDevicePivotId = uDevicePivotId
        self.query = query
        self.shorURL = shorURL
        self.responseBody = responseBody.data(using: String.Encoding.utf8
            )!
        
    }
    init() {
        self.init(groupId: 0, uDevicePivotId: 0,shorURL:"", query: "", responseBody: "")
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
