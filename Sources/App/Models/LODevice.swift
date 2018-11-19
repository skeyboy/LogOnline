//
//  LODeviceTag.swift
//  LogOnline
//
//  Created by sk on 2018/11/19.
//

import Foundation
import Vapor
import FluentMySQL
import MySQL
struct LODeviceRequest: Content {
    var uuid: String
    var deviceJsonInfo: String
    init(uuid: String,info deviceJsonInfo: String) {
        self.uuid = uuid
        self.deviceJsonInfo = deviceJsonInfo
    }
    public static var defaultContentType: MediaType {
        return MediaType.formData
    }
}
struct LODevice: MySQLModel {
    var id: Int?
    var uuid: String
    var deviceJsonInfo: String
    init(uuid: String,info deviceJsonInfo: String) {
        self.uuid = uuid
        self.deviceJsonInfo = deviceJsonInfo
    }
}
extension LODevice: MySQLMigration{}
extension LODevice: Content{}
