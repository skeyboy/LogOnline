import App
import Alamofire
import XCTest

final class AppTests: XCTestCase {
    let host = "http://0.0.0.0:8080/"
    var  shouldKeepRunning: Bool = false
    override func setUp() {
        
    }
    func testNothing() throws {
        // add your tests here
        XCTAssert(true)
    }
    func testLogin(){
       let login = "login?userIdentifier=123&groupName=ELB-T&groupIdetifier=1542678913.160826"
        Alamofire.request(host+login).responseJSON { (data:DataResponse<Any>) in
            print(data.result.value)
            self.endRun()
        }
        startRun()
    }
    func startRun() -> Void {
        shouldKeepRunning = true
        while shouldKeepRunning && RunLoop.current.run(mode: RunLoopMode.defaultRunLoopMode, before: Date.distantFuture) {
            
        }
    }
    func endRun() -> Void {
        shouldKeepRunning = false
    }
    func testRegistGroup(){
      let group = "regist/group?name=ELB-T"
        Alamofire.request(self.host + group).responseJSON(queue: DispatchQueue.main
        , options: JSONSerialization.ReadingOptions.allowFragments) { (data:DataResponse<Any>) in
            print(data.result.value)
            self.endRun()
        }
        startRun()
    }
    func testDeviceRegist(){
let deviceRegist = "log/api/regist/device?uuid=dddssd&deviceJsonInfo=234334"
        let headers: HTTPHeaders = [
            "Authorization": "Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==",
            "vapor-session":"zu24jSPGIAH82WY+0kKndw=="
        ]
        Alamofire.request( host + deviceRegist,
                           headers: headers ).responseJSON { (data:DataResponse<Any>) in
            print(data.result.value)
            self.endRun()
        }
        startRun()
        
    }
    func testCreateLog(){
        
    }
    
    static let allTests = [
        ("testNothing", testNothing)
    ]
}
