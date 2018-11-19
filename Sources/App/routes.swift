import Vapor
import Authentication
extension LOUser: SessionAuthenticatable{}

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    
    let logAPI = router.grouped("/log/api")
        .grouped(SessionsMiddleware.self);
    // Basic "It works" example
    router.get { req in
        return "It works!"
    }
    
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }
    
    router.get("regist/group") { (req:Request) -> EventLoopFuture<LOGroup> in
        var group = try req.query.decode(LOGroup.self)
        group.idetifier = "\(Date().timeIntervalSince1970)"
        group.createTime = Date().timeIntervalSince1970
        return LOGroup.query(on: req)
            .filter(\.name, .equal, group.name)
            .first()
            .flatMap({ (inner:LOGroup?) -> EventLoopFuture<LOGroup> in
                if inner == nil {
                    return group.create(on: req)
                    
                }else{
                    let result = req.eventLoop.newPromise(LOGroup.self)
                    result.succeed(result: inner!)
                    return result.futureResult
                }
            })
    }
    
    logAPI.post("create/log") { (req:Request) -> EventLoopFuture<String>  in
        do{
            let loSession = try req.authenticatedSession(LOUser.self)
            
            struct Log: Content {
                var groupId: Int
                var uDevicePivotId: Int
                var query: String
                var responseBody: String
            }
            return try req.content.decode(Log.self).flatMap({ (log:Log) -> EventLoopFuture<String> in
                return   LOLog.init( groupId: log.groupId, uDevicePivotId:log.uDevicePivotId, query: log.query, responseBody: log.responseBody)
                    .create(on: req).flatMap({ (log:LOLog) -> EventLoopFuture<String> in
                        let result = req.eventLoop.newPromise(String.self)
                        result.succeed(result: "\(log)")
                        return result.futureResult
                    })
            })
        }catch{
            let result = req.eventLoop.newPromise(String.self)
            result.succeed(result: "\(error)")
            return result.futureResult
        }
    }
    //根据生成uuid进行设备信息注册
    router.post("regist/device") { (req:Request) -> EventLoopFuture<LODevice> in
        return try req.content.decode(LODeviceRequest.self).flatMap({ (deviceReq:LODeviceRequest) -> EventLoopFuture<LODevice> in
            LODevice.query(on: req).filter(\.uuid, .equal, deviceReq.uuid).first().flatMap({ (device:LODevice?) -> EventLoopFuture<LODevice> in
                if device == nil {
                    return  LODevice.init(uuid: deviceReq.uuid, info: deviceReq.deviceJsonInfo).create(on: req)
                }else{
                    let result = req.eventLoop.newPromise(LODevice.self)
                    result.succeed(result: device!)
                    return result.futureResult
                }
            })
        })
    }
    
    router.get("login") { (req) -> EventLoopFuture<LOUser> in
        let  loSession =   try? req.authenticatedSession(LOUser.self)
        if loSession != nil {
            return LOUser.find(loSession! as! Int  , on: req).flatMap({ (user:LOUser?) -> EventLoopFuture<LOUser> in
                if let user = user {
                    let result = req.eventLoop.newPromise(LOUser.self)
                    result.succeed(result: user)
                    return result.futureResult
                }else{
                    return  login(req: req)
                }
            })
            
        }else{
            return login(req: req)
        }
    }
    
   
}
