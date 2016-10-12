//
//  UploadTaskDelegate.swift
//  Alamofire
//
//  Created by Vlad Gorbenko on 10/12/16.
//  Copyright © 2016 Alamofire. All rights reserved.
//

import Foundation

// MARK: -

class UploadTaskDelegate: DataTaskDelegate {
    
    // MARK: Properties
    
    var uploadTask: URLSessionUploadTask { return task as! URLSessionUploadTask }
    
    var uploadProgress: Progress
    var uploadProgressHandler: (closure: Request.ProgressHandler, queue: DispatchQueue)?
    
    // MARK: Lifecycle
    
    override init(task: URLSessionTask?) {
        uploadProgress = Progress(totalUnitCount: 0)
        super.init(task: task)
    }
    
    override func reset() {
        super.reset()
        uploadProgress = Progress(totalUnitCount: 0)
    }
    
    // MARK: URLSessionTaskDelegate
    
    var taskDidSendBodyData: ((URLSession, URLSessionTask, Int64, Int64, Int64) -> Void)?
    
    func URLSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64)
    {
        print("\(#line) " + #function)
        if initialResponseTime == nil { initialResponseTime = CFAbsoluteTimeGetCurrent() }
        
        if let taskDidSendBodyData = taskDidSendBodyData {
            taskDidSendBodyData(session, task, bytesSent, totalBytesSent, totalBytesExpectedToSend)
        } else {
            uploadProgress.totalUnitCount = totalBytesExpectedToSend
            uploadProgress.completedUnitCount = totalBytesSent
            
            if let uploadProgressHandler = uploadProgressHandler {
                uploadProgressHandler.queue.async { uploadProgressHandler.closure(self.uploadProgress) }
            }
        }
    }
}
