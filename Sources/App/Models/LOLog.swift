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
    var responseBody:String
    var mode: Int = LogMode.debug.rawValue
    var level: Int = LogLevel.info.rawValue
    var date: String
    init( groupId: Int, uDevicePivotId: Int, shortURL: String, query: String, responseBody: String, mode:LogMode = LogMode.debug, level: LogLevel = LogLevel.info) {
        self.groupId = groupId
        self.uDevicePivotId = uDevicePivotId
        self.query = query
        self.shortURL = shortURL
        //        self.responseBody = responseBody.data(using: String.Encoding.utf8
        //            )!
        self.responseBody = responseBody
        
        self.mode = mode.rawValue
        self.level  = level.rawValue
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"//YYYY-MM-DD HH:MM:SS

        
        self.date = formatter.string(from: Date.init())
    }
    
    static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return MySQLDatabase.create(self, on: connection) { builder in
            
            builder.field(for: \.id, type: MySQLDataType.int, MySQLColumnConstraint.primaryKey())
            builder.field(for: \.uDevicePivotId)
            builder.field(for:\.groupId,type:.int, MySQLColumnConstraint.notNull())
            builder.field(for: \.shortURL)
            builder.field(for: \.responseBody, type: .text)
            builder.field(for: \.query)
            builder.field(for: \.mode)
            builder.field(for: \.level)
            builder.field(for: \.date, type: .datetime )
        }
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
