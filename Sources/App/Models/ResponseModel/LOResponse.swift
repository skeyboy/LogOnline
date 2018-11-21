//
//  LOResponse.swift
//  LogOnline
//
//  Created by sk on 2018/11/20.
//

import Foundation
import Vapor
struct  LOResponse<T: Content> {
    var code: LOResponseStatus
    var data: T
    var msg: String
    init(code: LOResponseStatus = .ok, data:T, msg: String = "OK") {
        self.code = code
        self.data = data
        self.msg = msg
    }
}
extension LOResponse: Content{}
enum LOResponseStatus: Int{
    case ok
    case failure
    case noAuth
}
extension LOResponseStatus : Content{}
