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

