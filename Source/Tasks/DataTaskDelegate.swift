//
//  DataTaskDelegate.swift
//  Alamofire
//
//  Created by Vlad Gorbenko on 10/12/16.
//  Copyright © 2016 Alamofire. All rights reserved.
//

import Foundation

// MARK: -

class DataTaskDelegate: TaskDelegate, URLSessionDataDelegate {
    
    // MARK: Properties
    
    var dataTask: URLSessionDataTask { return task as! URLSessionDataTask }
    
    override var data: Data? {
        if dataStream != nil {
            return nil
        } else {
            return mutableData
        }
    }
    
    var progress: Progress
    var progressHandler: (closure: Request.ProgressHandler, queue: DispatchQueue)?
    
    var dataStream: ((_ data: Data) -> Void)?
    
    private var totalBytesReceived: Int64 = 0
    private var mutableData: Data
    
    private var expectedContentLength: Int64?
    
    // MARK: Lifecycle
    
    override init(task: URLSessionTask?) {
        mutableData = Data()
        progress = Progress(totalUnitCount: 0)
        
        super.init(task: task)
    }
    
    override func reset() {
        super.reset()
        
        progress = Progress(totalUnitCount: 0)
        totalBytesReceived = 0
        mutableData = Data()
        expectedContentLength = nil
    }
    
    // MARK: URLSessionDataDelegate
    
    var dataTaskDidReceiveResponse: ((URLSession, URLSessionDataTask, URLResponse) -> URLSession.ResponseDisposition)?
    var dataTaskDidBecomeDownloadTask: ((URLSession, URLSessionDataTask, URLSessionDownloadTask) -> Void)?
    var dataTaskDidReceiveData: ((URLSession, URLSessionDataTask, Data) -> Void)?
    var dataTaskWillCacheResponse: ((URLSession, URLSessionDataTask, CachedURLResponse) -> CachedURLResponse?)?
    
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void)
    {
        var disposition: URLSession.ResponseDisposition = .allow
        
        expectedContentLength = response.expectedContentLength
        
        if let dataTaskDidReceiveResponse = dataTaskDidReceiveResponse {
            disposition = dataTaskDidReceiveResponse(session, dataTask, response)
        }
        
        completionHandler(disposition)
    }
    
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didBecome downloadTask: URLSessionDownloadTask)
    {
        dataTaskDidBecomeDownloadTask?(session, dataTask, downloadTask)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if initialResponseTime == nil { initialResponseTime = CFAbsoluteTimeGetCurrent() }
        if let dataTaskDidReceiveData = dataTaskDidReceiveData {
            dataTaskDidReceiveData(session, dataTask, data)
        } else {
            if let dataStream = dataStream {
                dataStream(data)
            } else {
                mutableData.append(data)
            }
            
            let bytesReceived = Int64(data.count)
            totalBytesReceived += bytesReceived
            let totalBytesExpected = dataTask.response?.expectedContentLength ?? NSURLSessionTransferSizeUnknown
            
            progress.totalUnitCount = totalBytesExpected
            progress.completedUnitCount = totalBytesReceived
            
            if let progressHandler = progressHandler {
                progressHandler.queue.async { progressHandler.closure(self.progress) }
            }
        }
    }
    
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        willCacheResponse proposedResponse: CachedURLResponse,
        completionHandler: @escaping (CachedURLResponse?) -> Void)
    {
        var cachedResponse: CachedURLResponse? = proposedResponse
        
        if let dataTaskWillCacheResponse = dataTaskWillCacheResponse {
            cachedResponse = dataTaskWillCacheResponse(session, dataTask, proposedResponse)
        }
        
        completionHandler(cachedResponse)
    }
}
