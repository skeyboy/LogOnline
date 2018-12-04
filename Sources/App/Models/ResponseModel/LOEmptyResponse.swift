//
//  LOLogResponse.swift
//  LogOnline
//
//  Created by sk on 2018/11/20.
//

import Foundation
import Vapor
import SwiftProtobuf
struct LOEmptyResponse : Content {}
/*
struct PB<T> : Content where T: Message{
    var value: Data
    init(_ data: T) throws {
        self.value = try data.serializedData()
    }
}
extension PB{
    var entry:T? {
       return  try? T(serializedData:value)
    }
}
extension PB{
    public static func with<T>(_ populator:( inout T)->()) throws -> PB<T> where T: Message{
        var p = T.init()
        populator(&p)
        let pb = try  PB<T>.init(p)
        return pb
    }
}
extension PB{
    var textString:String{
        guard let entry = self.entry else {
            return ""
        }
        return entry.textFormatString()
    }
}
extension PB: CustomDebugStringConvertible, CustomStringConvertible{
    var description: String {
        return "\(self)"
    }
    
    var debugDescription: String{
        return "Debug:\(self)"
    }
}
extension PB: Equatable{
    public static func ==  (lhs: PB, rhs: PB) -> Bool {
        if lhs.entry == nil || rhs.entry == nil {
            return false
        }
        return "\(String(describing: lhs.entry))" == "\(String(describing: rhs.entry))"
    }
}

extension Request{
    func makePB<T>(value: T) throws -> EventLoopFuture<PB<T>> where T: Message{
        let result = self.eventLoop.newPromise(PB<T>.self)
        
        let pb = try PB.init(value)
        
        result.succeed(result: pb)
        
        return result.futureResult
    }
}
 */
