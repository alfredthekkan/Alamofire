//
//  DownloadTaskDelegate.swift
//  Alamofire
//
//  Created by Vlad Gorbenko on 10/12/16.
//  Copyright © 2016 Alamofire. All rights reserved.
//

import Foundation

// MARK: -

class DownloadTaskDelegate: TaskDelegate, URLSessionDownloadDelegate {
    
    // MARK: Properties
    
    var downloadTask: URLSessionDownloadTask { return task as! URLSessionDownloadTask }
    
    var progress: Progress
    var progressHandler: (closure: Request.ProgressHandler, queue: DispatchQueue)?
    
    var resumeData: Data?
    override var data: Data? { return resumeData }
    
    var destination: DownloadRequest.DownloadFileDestination?
    
    var temporaryURL: URL?
    var destinationURL: URL?
    
    var fileURL: URL? { return destination != nil ? destinationURL : temporaryURL }
    
    // MARK: Lifecycle
    
    override init(task: URLSessionTask?) {
        progress = Progress(totalUnitCount: 0)
        super.init(task: task)
    }
    
    override func reset() {
        super.reset()
        
        progress = Progress(totalUnitCount: 0)
        resumeData = nil
    }
    
    // MARK: URLSessionDownloadDelegate
    
    var downloadTaskDidFinishDownloadingToURL: ((URLSession, URLSessionDownloadTask, URL) -> URL)?
    var downloadTaskDidWriteData: ((URLSession, URLSessionDownloadTask, Int64, Int64, Int64) -> Void)?
    var downloadTaskDidResumeAtOffset: ((URLSession, URLSessionDownloadTask, Int64, Int64) -> Void)?
    
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL)
    {
        print("\(#line) " + #function)
        temporaryURL = location
        
        if let destination = destination {
            let result = destination(location, downloadTask.response as! HTTPURLResponse)
            let destination = result.destinationURL
            let options = result.options
            
            do {
                destinationURL = destination
                
                if options.contains(.removePreviousFile) {
                    if FileManager.default.fileExists(atPath: destination.path) {
                        try FileManager.default.removeItem(at: destination)
                    }
                }
                
                if options.contains(.createIntermediateDirectories) {
                    let directory = destination.deletingLastPathComponent()
                    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
                }
                
                try FileManager.default.moveItem(at: location, to: destination)
            } catch {
                self.error = error
            }
        }
    }
    
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64)
    {
        print("\(#line) " + #function)
        if initialResponseTime == nil { initialResponseTime = CFAbsoluteTimeGetCurrent() }
        
        if let downloadTaskDidWriteData = downloadTaskDidWriteData {
            downloadTaskDidWriteData(
                session,
                downloadTask,
                bytesWritten,
                totalBytesWritten,
                totalBytesExpectedToWrite
            )
        } else {
            progress.totalUnitCount = totalBytesExpectedToWrite
            progress.completedUnitCount = totalBytesWritten
            
            if let progressHandler = progressHandler {
                progressHandler.queue.async { progressHandler.closure(self.progress) }
            }
        }
    }
    
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didResumeAtOffset fileOffset: Int64,
        expectedTotalBytes: Int64)
    {
        print("\(#line) " + #function)
        if let downloadTaskDidResumeAtOffset = downloadTaskDidResumeAtOffset {
            downloadTaskDidResumeAtOffset(session, downloadTask, fileOffset, expectedTotalBytes)
        } else {
            progress.totalUnitCount = expectedTotalBytes
            progress.completedUnitCount = fileOffset
        }
    }
}
