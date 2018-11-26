//
//  LOGroupScanREsponse.swift
//  LogOnline
//
//  Created by sk on 2018/11/26.
//

import Foundation
import Vapor

struct LOGroupScanResponse : Content {
    
    var pivot: LOUserDevicePivot
    
    var device: LODevice
    init(p pivot: LOUserDevicePivot, d device: LODevice) {
        self.pivot = pivot
        self.device = device
    }
}
