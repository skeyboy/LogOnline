
import Foundation
import Vapor
import Core
import Bits
extension Request{
    
    var publicPath: String{
        let path =  try! self.sharedContainer.make(DirectoryConfig.self).workDir + "Public/"
        return path
    }
    
}
public func genereatePDF(_ urlString: String , destDir: String, worker: Container)throws -> EventLoopFuture<String>{
    let result = worker.eventLoop.newPromise(String.self)
    let relativePath = "\(urlString.components(separatedBy: "/").last!).pdf"
    let filepath = "\(destDir)" + relativePath
    
    let fileManager = FileManager.default
    
    if( fileManager.fileExists(atPath: filepath ) ){
        result.succeed(result: relativePath)
    }else{
    gennerXPDF(from: urlString) { (stdout:Pipe) in
        
        let data =
            stdout.fileHandleForReading.readDataToEndOfFile()
       
        try! FileManager.default.createFile(atPath: filepath
            , contents: data
            , attributes: nil)
        
        result.succeed(result: relativePath)
        }
        
    }
    return result.futureResult
}
func gennerXPDF(from url: String, result:(Pipe)->Void)->Void{
    let wk = Process()
    let stdout = Pipe()
     wk.launchPath = "/usr/local/bin/wkhtmltopdf"
     wk.arguments = [   "--dump-outline","toc" ,url ]
    wk.arguments?.append("-") // output to stdout
    wk.standardOutput = stdout
    wk.launch()
    result(stdout)
}

