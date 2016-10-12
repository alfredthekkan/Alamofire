//
//  DataRequest.swift
//  Alamofire
//
//  Created by Vlad Gorbenko on 10/12/16.
//  Copyright © 2016 Alamofire. All rights reserved.
//

import Foundation

// MARK: -

/// Specific type of `Request` that manages an underlying `URLSessionDataTask`.
open class DataRequest: Request {
    
    // MARK: Helper Types
    
    struct Requestable: TaskConvertible {
        let urlRequest: URLRequest
        
        func task(session: URLSession, adapter: RequestAdapter?, queue: DispatchQueue) throws -> URLSessionTask {
            let urlRequest = try self.urlRequest.adapt(using: adapter)
            return queue.syncResult { session.dataTask(with: urlRequest) }
        }
    }
    
    // MARK: Properties
    
    /// The progress of fetching the response data from the server for the request.
    open var progress: Progress { return dataDelegate.progress }
    
    var dataDelegate: DataTaskDelegate { return delegate as! DataTaskDelegate }
    
    // MARK: Stream
    
    /// Sets a closure to be called periodically during the lifecycle of the request as data is read from the server.
    ///
    /// This closure returns the bytes most recently received from the server, not including data from previous calls.
    /// If this closure is set, data will only be available within this closure, and will not be saved elsewhere. It is
    /// also important to note that the server data in any `Response` object will be `nil`.
    ///
    /// - parameter closure: The code to be executed periodically during the lifecycle of the request.
    ///
    /// - returns: The request.
    @discardableResult
    open func stream(closure: ((Data) -> Void)? = nil) -> Self {
        dataDelegate.dataStream = closure
        return self
    }
    
    // MARK: Progress
    
    /// Sets a closure to be called periodically during the lifecycle of the `Request` as data is read from the server.
    ///
    /// - parameter queue:   The dispatch queue to execute the closure on.
    /// - parameter closure: The code to be executed periodically as data is read from the server.
    ///
    /// - returns: The request.
    @discardableResult
    open func downloadProgress(queue: DispatchQueue = DispatchQueue.main, closure: @escaping ProgressHandler) -> Self {
        dataDelegate.progressHandler = (closure, queue)
        return self
    }
}
