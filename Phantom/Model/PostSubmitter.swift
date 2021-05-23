//
//  PostSubmitter.swift
//  Phantom
//
//  Created by Rivershy on 2020/09/03.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation

class PostSubmitter {
    typealias SubmitCallback = (_ result: Result<String, Error>) -> Void
    
    struct SubmitParams {
        let wallpaperMode: Bool
        let useWallhaven: Bool
    }
    
    private class PostSubmission: Operation {
        private let reddit: Reddit
        private let post: Post
        private let callback: SubmitCallback
        private let middlewares: [RequiredMiddleware]
        private let params: SubmitParams
        private let retryStrategy: RetryStrategy
        
        init(reddit: Reddit,
             post: Post,
             params: SubmitParams,
             imgur: Imgur? = nil,
             callback: @escaping SubmitCallback) {
            
            self.reddit = reddit
            self.post = post
            self.callback = callback
            self.params = params
            self.retryStrategy = RetryStrategy.delay(maxRetryCount: 5, retryInterval: 3)
            
            self.middlewares = PostSubmission.getMiddlewares(params: params, imgur: imgur)
        }
        
        convenience init(reddit: Reddit,
                         database: Database,
                         params: SubmitParams,
                         imgur: Imgur? = nil,
                         callback: @escaping SubmitCallback) {
            
            let post = PostSubmission.getPost(database: database)
            
            self.init(reddit: reddit, post: post, params: params, callback: callback)
        }
        
        private static func getMiddlewares(params: SubmitParams, imgur: Imgur?) -> [RequiredMiddleware] {
            var mw = [RequiredMiddleware]()
            
            if params.useWallhaven {
                let wallhavenMw = RequiredMiddleware(middleware: WallhavenMiddleware(), isRequired: params.useWallhaven)
                mw.append(wallhavenMw)
            }
            
            if let imgur = imgur {
                let innerImgurMw = ImgurMiddleware(imgur, wallpaperMode: params.wallpaperMode)
                let imgurMw = RequiredMiddleware(middleware: innerImgurMw, isRequired: params.wallpaperMode)
                mw.append(imgurMw)
            } else if params.wallpaperMode {
                fatalError("Imgur is required for wallpaper mode") // todo: make this scenario unreachable
            }
            
            return mw
        }
        
        private static func getPost(database: Database) -> Post {
            return database.posts.last!
        }
        
        private func executeMiddlewares(on post: Post) throws -> Post {
            guard !DebugVariable.simulateMiddleware else {
                sleep(1)
                return post
            }
            
            var middlewaredPost = post
            for middleware in middlewares {
                let middlewared = try middleware.transform(post: middlewaredPost)
                
                middlewaredPost = middlewared.post
                let postChanged = middlewared.changed
                
                if middleware.isRequired && !postChanged {
                    throw PhantomError.requiredMiddlewareNoEffect(middleware: String(describing: middleware.middleware))
                }
                
                // todo: handle imgur 10 MB error
            }
            
            return middlewaredPost
        }
        
        private func submitMiddlewaredPost(_ mp: Post) throws -> String {
            guard !DebugVariable.simulateReddit else {
                sleep(3)
                
                return "https://simulated-url-lolz.com/"
            }
            
            // todo: send isCancelled closure into reddit.submit() so that it can check that at every step
            let url = try reddit.submit(post: mp)
            return url
        }
        
        private func submitPost() throws -> String {
            let middlewaredPost = try executeMiddlewares(on: post)
            let url = try submitMiddlewaredPost(middlewaredPost)
            
            return url
        }
        
        override func main() {
            guard !isCancelled else { return } // we need more of these in this method (actually everywhere in this class)
            
            Log.p("submission task started")
            
            switch retryStrategy {
            case .delay(let maxRetryCount, let retryInterval):
                
                var retryCount = 0
                var lastError: Error?
                
                while retryCount < maxRetryCount {
                    if retryCount > 0 {
                        Log.p("Attempt #\(retryCount + 1)")
                    }
                    
                    let errorHappened: Bool
                    var url: String?
                    do {
                        url = try submitPost()
                        errorHappened = false
                    } catch {
                        Log.p("Unexpected error while submitting", error)
                        lastError = error
                        errorHappened = true
                    }
                    
                    if errorHappened {
                        retryCount += 1
                        Log.p("Waiting...")
                        Thread.sleep(forTimeInterval: retryInterval)
                        Log.p("Done waiting")
                    } else {
                        callback(.success(url!))
                        return
                    }
                }
                
                callback(.failure(lastError!))
                    
            case .noRetry:
                
                let url: String
                do {
                    url = try submitPost()
                } catch {
                    Log.p("Unexpected error while submitting", error)
                    callback(.failure(error))
                    return
                }
                
                callback(.success(url))
            }
        }
    }
    
    static let instance = PostSubmitter()
    
    var reddit = Atomic<Reddit?>(nil)
    var imgur = Atomic<Imgur?>(nil)
    
    private lazy var submitQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "Submit queue"
        queue.maxConcurrentOperationCount = 1
        
        return queue
    }()
    
    private init() { }
    
    private func addToQueue(submission: PostSubmission) {
        submission.completionBlock = {
            guard !submission.isCancelled else { return }
            
            Log.p("submission task complete")
        }
        
        submitQueue.addOperation(submission)
    }
    
    func submitPost(_ post: Post, with params: SubmitParams, callback: @escaping SubmitCallback) { // todo: disable submission while logged out
        guard let reddit = reddit.value,
              let imgur = imgur.value
        else {
            fatalError()
        }
        
        let submission = PostSubmission(reddit: reddit,
                                        post: post,
                                        params: params,
                                        imgur: imgur,
                                        callback: callback)
        
        addToQueue(submission: submission)
    }
    
    func submitPostInDatabase(_ database: Database, with params: SubmitParams, callback: @escaping SubmitCallback) {
        guard let reddit = reddit.value,
              let imgur = imgur.value
        else {
            fatalError()
        }
        
        let submission = PostSubmission(reddit: reddit,
                                        database: database,
                                        params: params,
                                        imgur: imgur,
                                        callback: callback)
        
        addToQueue(submission: submission)
    }
    
    func cancelEverything() {
        submitQueue.cancelAllOperations()
    }
}
