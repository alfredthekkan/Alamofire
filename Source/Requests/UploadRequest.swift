//
//  UploadRequest.swift
//  Alamofire
//
//  Created by Vlad Gorbenko on 10/12/16.
//  Copyright © 2016 Alamofire. All rights reserved.
//

import Foundation

// MARK: -

/// Specific type of `Request` that manages an underlying `URLSessionUploadTask`.
open class UploadRequest: DataRequest {
    
    // MARK: Helper Types
    
    enum Uploadable: TaskConvertible {
        case data(Data, URLRequest)
        case file(URL, URLRequest)
        case stream(InputStream, URLRequest)
        
        func task(session: URLSession, adapter: RequestAdapter?, queue: DispatchQueue) throws -> URLSessionTask {
            let task: URLSessionTask
            
            switch self {
            case let .data(data, urlRequest):
                let urlRequest = try urlRequest.adapt(using: adapter)
                task = queue.syncResult { session.uploadTask(with: urlRequest, from: data) }
            case let .file(url, urlRequest):
                let urlRequest = try urlRequest.adapt(using: adapter)
                task = queue.syncResult { session.uploadTask(with: urlRequest, fromFile: url) }
            case let .stream(_, urlRequest):
                let urlRequest = try urlRequest.adapt(using: adapter)
                task = queue.syncResult { session.uploadTask(withStreamedRequest: urlRequest) }
            }
            
            return task
        }
    }
    
    // MARK: Properties
    
    /// The progress of uploading the payload to the server for the upload request.
    open var uploadProgress: Progress { return uploadDelegate.uploadProgress }
    
    var uploadDelegate: UploadTaskDelegate { return delegate as! UploadTaskDelegate }
    
    // MARK: Upload Progress
    
    /// Sets a closure to be called periodically during the lifecycle of the `UploadRequest` as data is sent to
    /// the server.
    ///
    /// After the data is sent to the server, the `progress(queue:closure:)` APIs can be used to monitor the progress
    /// of data being read from the server.
    ///
    /// - parameter queue:   The dispatch queue to execute the closure on.
    /// - parameter closure: The code to be executed periodically as data is sent to the server.
    ///
    /// - returns: The request.
    @discardableResult
    open func uploadProgress(queue: DispatchQueue = DispatchQueue.main, closure: @escaping ProgressHandler) -> Self {
        uploadDelegate.uploadProgressHandler = (closure, queue)
        return self
    }
}
