import Vapor
import FluentMySQL
import Authentication
import SwiftVaporPB
extension LOUser: SessionAuthenticatable{}

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    
    router.get("/") { (req) -> EventLoopFuture<View> in
        return try req.view().render("index")
    }
    router.get("html2pdf") { (req:Request) -> EventLoopFuture<View> in
        struct PDF : Content {
            var url: String
        }
        let pdf: PDF = try req.query.decode(PDF.self)
        
        return try genereatePDF( pdf.url, destDir: req.publicPath, worker: req).then({ (fileUrl:String) -> EventLoopFuture<View> in
            
            
            return try!  req.view().render("pdf", PDF.init(url: fileUrl))
        })
    }
    
    router.get("pb") { (req:Request) -> EventLoopFuture<PB<BookInfo>> in
        let bookInfo =   BookInfo.with({ ( bookInfo:inout BookInfo) in
            bookInfo.id = 123
            bookInfo.author = "Jack"
            bookInfo.title = "Hello"
        })
        let binaryData: Data = try! bookInfo.serializedData()

         return try req.makePB(value: bookInfo)
    }
    // Basic "Hello, world!" example
    router.get("hello") { req in
        
        return "Hello, world!"
    }
    
    
    
    
    let logAPI = router.grouped("log/api/")
        .grouped(SessionsMiddleware.self);
    // groudId 获取 用户 等基本信息
    router.get("group/scan") { (req:Request) -> EventLoopFuture<LOResponse<[LOGroupScanResponse]>> in
        struct GroupScanReq: Content {
            var groupdId: Int?
            var pno: Int?
            var max: Int?
        }
        
        var gq = try! req.query.decode(GroupScanReq.self)
        var queryBuilder =   LOGroup.query(on: req)
        
        if gq.groupdId != nil {
        queryBuilder =    queryBuilder.filter(\.id, .equal, gq.groupdId)
        }
        if gq.pno == nil {
            gq.pno = 1
        }
        if gq.max == nil {
            gq.max = 20
        }
      queryBuilder =  queryBuilder.range(lower: (gq.pno! - 1) * (gq.max!), upper: gq.pno! * gq.max!)
        
     return  queryBuilder
        .all()
            .flatMap({ (groupds:[LOGroup]) -> EventLoopFuture<[LOGroupUserPivot]> in
          let groupPs =  groupds.map({ (group:LOGroup) -> EventLoopFuture<LOGroupUserPivot> in
                return LOGroupUserPivot.query(on: req).filter(\LOGroupUserPivot.groupId, .equal, group.id!).first().map({ (p:LOGroupUserPivot?) -> (LOGroupUserPivot) in
                    return p!
                })
            })
            
            return groupPs.flatten(on: req)
            }).flatMap({ (gps:[LOGroupUserPivot]) -> EventLoopFuture<[[(LOUserDevicePivot, LODevice)]]> in
                
              let devices =  gps.map({ (gp:LOGroupUserPivot) -> EventLoopFuture<[(LOUserDevicePivot, LODevice)]> in
                
             return   LOUserDevicePivot.query(on: req)
                    .filter(\LOUserDevicePivot.userId, .equal, gp.userId)
                    .all().flatMap({ (item:[LOUserDevicePivot]) -> EventLoopFuture<[(LOUserDevicePivot, LODevice)]> in
                        
                        let items =    item.map({ (udp:LOUserDevicePivot) -> EventLoopFuture<(LOUserDevicePivot,LODevice) > in
                        return LODevice.find(udp.deviceId, on: req).map({ (d:LODevice?) -> (LOUserDevicePivot,LODevice) in
                                
                            return (udp, d!)
                            })
                        })
                     return   items.flatten(on: req)
                    })

                })
              return  devices.flatten(on: req)
             }).flatMap({ (items:[[(LOUserDevicePivot, LODevice)]]) -> EventLoopFuture<[LOGroupScanResponse]> in
                let values = items.compactMap({ (item:[(LOUserDevicePivot, LODevice)]) -> [LOGroupScanResponse] in
                   return item.map({ (i:(LOUserDevicePivot, LODevice)) -> LOGroupScanResponse in
                         return LOGroupScanResponse.init(p: i.0, d: i.1)
                    })
                   
                })
                var container = [LOGroupScanResponse]()
                for i in values {
                    container.append(contentsOf: i)
                }
                let result = req.eventLoop.newPromise([LOGroupScanResponse].self)
                result.succeed(result: container)
                return result.futureResult
            }).flatMap({ (items:[LOGroupScanResponse]) -> EventLoopFuture<LOResponse<[LOGroupScanResponse]>> in
                
                let value =   LOResponse<[LOGroupScanResponse]>.init(code: LOResponseStatus.ok, data:items, msg: "OK")
                
                let result = req.eventLoop.newPromise(LOResponse<[LOGroupScanResponse]>.self)
                
                result.succeed(result: value)
                return result.futureResult
            })
    }
    // log/detail?logId=12
    router.get("log/detail") { (req:Request) -> EventLoopFuture<LOResponse<LOLogScanDetail>>  in
        struct LogDetail: Content {
            var logId: Int
            var groupId: Int?
        }
        do{
            let logDetail: LogDetail = try  req.query.decode(LogDetail.self)
            
            return       LOLog.find(logDetail.logId, on: req).flatMap({ (log:LOLog?) -> EventLoopFuture<LOResponse<LOLogScanDetail>>  in
                let result = req.eventLoop.newPromise(LOResponse<LOLogScanDetail>.self)
                result.succeed(result: LOResponse<LOLogScanDetail>.init(code: LOResponseStatus.failure, data: LOLogScanDetail.init(detail: log), msg: "OK"))
                return result.futureResult
            })
            
        }catch{
            let result = req.eventLoop.newPromise(LOResponse<LOLogScanDetail>.self)
            result.succeed(result: LOResponse<LOLogScanDetail>.init(code: LOResponseStatus.failure, data: LOLogScanDetail.init(detail: nil), msg: "\(error)"))
            return result.futureResult
        }
    }
    
    /// log/scan?uDevicePivotId=2&groupId&mode=0&level=1&pno=0&max
    //查看日志 对应 组 + 当前设备
    router.get("log/scan") { (req:Request) ->
        EventLoopFuture<LOResponse<LOLogScanResponse>> in
        
        struct LogScan : Content {
            var uDevicePivotId : Int?
            var groupId : Int?
            var mode: LogMode = .debug
            var level: LogLevel = .info
            var pno: Int? = 0
            var max: Int? = 10
        }
        do{
            var logScan =  try req.query.decode(LogScan.self)
            
            if logScan.pno == nil || logScan.pno! <= 0 {
                logScan.pno = 1
            }
            if  logScan.max  == nil  || logScan.max! <= 0 {
                logScan.max = 10
            }
            var queryBuilder = LOLog.query(on: req)
            if nil !=  logScan.groupId {
            queryBuilder =    queryBuilder.filter(\LOLog.groupId, .equal, logScan.groupId!)
            }
            if nil != logScan.uDevicePivotId {
              queryBuilder =  queryBuilder.filter(\LOLog.uDevicePivotId, .equal, logScan.uDevicePivotId!)
            }
            return  queryBuilder.sort(\LOLog.id,.descending)
                .range(lower: logScan.max! * ( logScan.pno! - 1 ), upper: logScan.max! * logScan.pno!)
                .all()
                .flatMap({ ( logs :[ LOLog ] ) -> EventLoopFuture<LOResponse<LOLogScanResponse>> in
                    let items = logs.map({ (log:LOLog) -> LOLogScan in
                        let link = "http://\(req.http.headers[.host].first!)/log/detail?logId=\(String(describing: log.id!))"

                        return LOLogScan.init(
                            id: log.id!,
                            shortURL: log.shortURL
                            ,query:log.query,
                             body:nil,link:link)
                    })
                    let result = req.eventLoop.newPromise(LOResponse<LOLogScanResponse>.self)
                    result.succeed(result: LOResponse<LOLogScanResponse>.init(code: LOResponseStatus.ok, data: LOLogScanResponse(logs:items), msg: "OK"))
                    return result.futureResult
                    
                })
            
        }catch{
            
            
            let result = req.eventLoop.newPromise(LOResponse<LOLogScanResponse>.self)
            result.succeed(result: LOResponse<LOLogScanResponse>.init(code: LOResponseStatus.noAuth, data: LOLogScanResponse(logs:[LOLogScan]()), msg: "\(error)"))
            return result.futureResult
        }
    }
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
                var shortURL: String
                var query: String
                var responseBody: String
            }
            return try req.content.decode(Log.self)
                .flatMap({ (log:Log) -> EventLoopFuture<LOLog> in
                    return   LOLog.init( groupId: log.groupId, uDevicePivotId:log.uDevicePivotId,
                                         shortURL: log.shortURL,
                                         query: log.query, responseBody: log.responseBody)
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
