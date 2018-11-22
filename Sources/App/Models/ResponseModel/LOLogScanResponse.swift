//
//  LOLogScanResponse.swift
//  LogOnline
//
//  Created by sk on 2018/11/21.
//

import Foundation
import Vapor

struct LOLogScanResponse : Content {
    var logs : [ LOLogScan ]
}
struct LOLogScan : Content {
    var id: Int
    var shortURL: String
    var query : String
    var body : String
}
