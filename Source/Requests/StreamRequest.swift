//
//  StreamRequest.swift
//  Alamofire
//
//  Created by Vlad Gorbenko on 10/12/16.
//  Copyright © 2016 Alamofire. All rights reserved.
//

import Foundation

// MARK: -

#if !os(watchOS)
    
    /// Specific type of `Request` that manages an underlying `URLSessionStreamTask`.
    open class StreamRequest: Request {
        enum Streamable: TaskConvertible {
            case stream(hostName: String, port: Int)
            case netService(NetService)
            
            func task(session: URLSession, adapter: RequestAdapter?, queue: DispatchQueue) throws -> URLSessionTask {
                let task: URLSessionTask
                
                switch self {
                case let .stream(hostName, port):
                    task = queue.syncResult { session.streamTask(withHostName: hostName, port: port) }
                case let .netService(netService):
                    task = queue.syncResult { session.streamTask(with: netService) }
                }
                
                return task
            }
        }
    }
    
#endif
