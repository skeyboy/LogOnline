import Vapor
import FluentMySQL
import Authentication
extension LOUser: SessionAuthenticatable{}

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    
    let logAPI = router.grouped("log/api/")
        .grouped(SessionsMiddleware.self);
    
    
    //创建组
    router.get("regist/group") { (req:Request) ->  EventLoopFuture<LOResponse<LOGroup>>  in
        var group = try req.query.decode(LOGroup.self)
        if group.idetifier == nil {
            group.idetifier = "\(Date().timeIntervalSince1970)"
        }
      return  req.transaction(on: .mysql, { (connection:MySQLConnection) -> EventLoopFuture<LOResponse<LOGroup>> in
            group.createTime = Date().timeIntervalSince1970
            return LOGroup.query(on: req)
                .filter(\.name, .equal, group.name)
                .filter(\LOGroup.idetifier, .equal, group.idetifier)
                .first()
                .flatMap({ (inner:LOGroup?) -> EventLoopFuture<LOGroup> in
                    if inner == nil {
                        return group.create(on: req)
                    }else{
                        let result = req.eventLoop.newPromise(LOGroup.self)
                        result.succeed(result: inner!)
                        return result.futureResult
                    }
                }).flatMap({ (group:LOGroup) -> EventLoopFuture<LOResponse<LOGroup>> in
                    let result = req.eventLoop.newPromise(LOResponse<LOGroup>.self)
                    result.succeed(result: LOResponse<LOGroup>.init(code: LOResponseStatus.ok, data: group, msg: "OK"))
                    return result.futureResult
                })
        })
        
    }
    
    // 用户组 + （device+user）组合
    logAPI.post("create/log") { (req:Request) -> EventLoopFuture<LOResponse<LOLog>>  in
        do{
            _ = try req.authenticatedSession(LOUser.self)
            struct Log: Content {
                var groupId: Int
                var uDevicePivotId: Int
                var query: String
                var responseBody: String
            }
            return try req.content.decode(Log.self)
                .flatMap({ (log:Log) -> EventLoopFuture<LOLog> in
                return   LOLog.init( groupId: log.groupId, uDevicePivotId:log.uDevicePivotId, query: log.query, responseBody: log.responseBody)
                    .create(on: req)
                }).flatMap({ (log:LOLog) -> EventLoopFuture<LOResponse<LOLog>> in
                    let result = req.eventLoop.newPromise(LOResponse<LOLog>.self)
                    result.succeed(result: LOResponse<LOLog>.init(code: .ok, data: log, msg: "OK"))
                    return result.futureResult
                })
        }catch{
            let result = req.eventLoop.newPromise(LOResponse<LOLog>.self)
            result.succeed(result: LOResponse<LOLog>.init(code: .ok, data: LOLog.init(), msg: "OK"))
            return result.futureResult
        }
    }
    //根据生成uuid进行设备信息注册
    logAPI.post("regist/device") { (req:Request) -> EventLoopFuture<LOResponse<LOUserDevicePivot>>  in
        let loSession = try req.authenticatedSession(LOUser.self)
        return try req.content.decode(LODeviceRequest.self).flatMap({ (deviceReq:LODeviceRequest) -> EventLoopFuture<LODevice> in
          return  LODevice.query(on: req).filter(\.uuid, .equal, deviceReq.uuid).first().flatMap({ (device:LODevice?) -> EventLoopFuture<LODevice> in
                if device == nil {
                    return  LODevice.init(uuid: deviceReq.uuid, info: deviceReq.deviceJsonInfo).create(on: req)
                }else{
                    let result = req.eventLoop.newPromise(LODevice.self)
                    result.succeed(result: device!)
                    return result.futureResult
                }
            })
        }).flatMap({ (device:LODevice) -> EventLoopFuture<LOUserDevicePivot> in
            
            //c防止重复创建 关联关系
        return    LOUserDevicePivot.query(on: req)
                .filter(\LOUserDevicePivot.deviceId, .equal, device.id!)
            .filter(\LOUserDevicePivot.userId, .equal, loSession!)
                .first().flatMap({ (pivot:LOUserDevicePivot?) -> EventLoopFuture<LOUserDevicePivot> in
                    if pivot == nil {
                        return  LOUserDevicePivot.init(userId: loSession! , deviceId: device.id!).create(on: req)
                    }else{
                        let result = req.eventLoop.newPromise(LOUserDevicePivot.self)
                        result.succeed(result: pivot!)
                        return result.futureResult
                    }
                })
            
        }).flatMap({ (pivot:LOUserDevicePivot) -> EventLoopFuture<LOResponse<LOUserDevicePivot>> in
            let result  = req.eventLoop.newPromise(LOResponse<LOUserDevicePivot>.self)
            result.succeed(result: LOResponse<LOUserDevicePivot>.init(code: LOResponseStatus.ok, data: pivot, msg: "OK"))
            return result.futureResult
        })
    }
   
    
    router.get("login") { (req) -> EventLoopFuture<LOResponse<LOUser>>  in
        let  loSession: Optional<Optional<Int>> =   try? req.authenticatedSession(LOUser.self) ?? nil
        
        if loSession! != nil {
            return LOUser.find(loSession! as! Int  , on: req).flatMap({ (user:LOUser?) -> EventLoopFuture<LOUser> in
                if let user = user {
                    let result = req.eventLoop.newPromise(LOUser.self)
                    result.succeed(result: user)
                    return result.futureResult
                }else{
                    return  login(req: req)
                }
            }).flatMap({ (user:LOUser) -> EventLoopFuture<LOResponse<LOUser>> in
                let result = req.eventLoop.newPromise(LOResponse<LOUser>.self)
                result.succeed(result: LOResponse<LOUser>.init(code: LOResponseStatus.ok, data: user, msg: "OK"))
                return result.futureResult
            })
            
        }else{
            return login(req: req).flatMap({ (user:LOUser) -> EventLoopFuture<LOResponse<LOUser>> in
                let result = req.eventLoop.newPromise(LOResponse<LOUser>.self)
                result.succeed(result: LOResponse<LOUser>.init(code: LOResponseStatus.ok, data: user, msg: "OK"))
                return result.futureResult
            })
        }
    }
    
   
}
