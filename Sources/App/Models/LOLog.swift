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
public enum LogMode: Int{
    case debug
    case product
}
public enum LogLevel: Int{
    case info
    case error
    case warn
}
extension LogLevel: Content{}
extension LogMode: Content{}

struct LOLog: MySQLModel {
    var id: Int?
    
    /// 用户 和 device的映射
    var uDevicePivotId: Int
    var groupId: Int
    var shortURL: String
    var query: String
    var responseBody:Data
    var mode: LogMode = .debug
    var level: LogLevel = .info
    
    init( groupId: Int, uDevicePivotId: Int, shortURL: String, query: String, responseBody: String, mode:LogMode = LogMode.debug, level: LogLevel = LogLevel.info) {
         self.groupId = groupId
        self.uDevicePivotId = uDevicePivotId
        self.query = query
        self.shortURL = shortURL
        self.responseBody = responseBody.data(using: String.Encoding.utf8
            )!
        self.mode = mode
        self.level  = level
        
    }
    init() {
        self.init(groupId: 0, uDevicePivotId: 0,shortURL:"", query: "", responseBody: "")
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
