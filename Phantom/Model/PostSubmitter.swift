//
//  PostSubmitter.swift
//  Phantom
//
//  Created by Rivershy on 2020/09/03.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation

// todo: show attempt count to user
// todo: let user change retry strategy

class PostSubmitter {
    typealias RedditPostUrl = String
    typealias SubmitResult = Result<RedditPostUrl, Error>
    typealias SubmitCallback = (_ result: SubmitResult) -> Void
    
    struct SubmitParams {
        let wallpaperMode: Bool
        let useWallhaven: Bool
    }
    
    private class PostSubmission: Operation {
        private typealias ProcessResult = Result<Post, Error>
        private typealias ProcessResultWithTries = Result<(post: Post, triesLeft: Int), Error>
        
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
            self.retryStrategy = DebugVariable.disableRetry ? .noRetry : .delay(delayRetryStrategy: DelayRetryStrategy(maxRetryCount: 5, retryInterval: 3))
            
            self.middlewares = PostSubmission.getMiddlewares(params: params, imgur: imgur)
        }
        
        convenience init(reddit: Reddit,
                         database: Database,
                         params: SubmitParams,
                         imgur: Imgur? = nil,
                         callback: @escaping SubmitCallback) {
            
            let post = PostSubmission.getPost(from: database)
            
            self.init(reddit: reddit, post: post, params: params, callback: callback)
        }
        
        private static func getMiddlewares(params: SubmitParams, imgur: Imgur?) -> [RequiredMiddleware] {
            var mw = [RequiredMiddleware]()
            
            if params.useWallhaven {
                let wallhavenMw = RequiredMiddleware(middleware: WallhavenMiddleware(), isRequired: params.useWallhaven)
                mw.append(wallhavenMw)
            }
            
            if let imgur = imgur {
                let innerImgurMw = ImgurMiddleware(imgur, wallpaperMode: params.wallpaperMode, directUpload: DebugVariable.directImgurUpload)
                let imgurMw = RequiredMiddleware(middleware: innerImgurMw, isRequired: params.wallpaperMode)
                mw.append(imgurMw)
            } else if params.wallpaperMode {
                fatalError("Imgur is required for wallpaper mode") // todo: make this scenario unreachable
            }
            
            return mw
        }
        
        private static func getPost(from database: Database) -> Post {
            return database.posts.last!
        }
        
        override func main() {
            guard !isCancelled else { return } // we need more of these in this method (actually everywhere in this class)
            
            Log.p("submission task started")
            
            let submitResult = processAndSubmit(retryStrategy: retryStrategy)
            callback(submitResult)
        }
        
        private func processAndSubmit(retryStrategy: RetryStrategy) -> SubmitResult {
            let strategy: DelayRetryStrategy
            
            switch retryStrategy {
            case .delay(let delayRetryStrategy):
                strategy = delayRetryStrategy
            default:
                strategy = DelayRetryStrategy(maxRetryCount: 1, retryInterval: nil)
            }
            
            let processedPost: Post
            let triesLeft: Int
            
            let processResult = PostSubmission.fullProcessPost(post, using: middlewares, strategy: strategy)
            switch processResult {
            case .success((let processedPost_, let triesLeft_)):
                processedPost = processedPost_
                triesLeft = triesLeft_
            case .failure(let error):
                return .failure(error)
            }
            
            let updatedStrategy = DelayRetryStrategy(maxRetryCount: triesLeft, retryInterval: strategy.retryInterval)
            
            let submitResult = PostSubmission.submitPost(processedPost, using: reddit, strategy: updatedStrategy)
            return submitResult
        }
        
        private static func submitPost(_ post: Post, using reddit: Reddit, strategy: DelayRetryStrategy) -> SubmitResult {
            var retryCount = 0
            var lastError: Error?
            
            while retryCount < strategy.maxRetryCount {
                if retryCount > 0 {
                    Log.p("Attempt #\(retryCount + 1)")
                }
                
                let submitResult = submitPost(post, using: reddit)
                switch submitResult {
                case .success(let url):
                    return .success(url)
                case .failure(let error):
                    lastError = error
                    retryCount += 1
                    
                    if let retryInterval = strategy.retryInterval {
                        Log.p("Waiting...")
                        Thread.sleep(forTimeInterval: retryInterval)
                        Log.p("Done waiting")
                    }
                }
            }
            
            return .failure(lastError!)
        }
        
        private static func submitPost(_ post: Post, using reddit: Reddit) -> SubmitResult {
            guard !DebugVariable.simulateReddit else {
                sleep(1)
                
                return .success("https://simulated-url-lolz.com/")
            }
            
            let url: RedditPostUrl
            do {
                // todo: send isCancelled closure into reddit.submit() so that it can check that at every step
                url = try reddit.submit(post: post)
            } catch {
                Log.p("Unexpected error while submitting", error)
                return .failure(error)
            }
            
            return .success(url)
        }
        
        private static func fullProcessPost(_ post: Post, using middlewares: [RequiredMiddleware], strategy: DelayRetryStrategy) -> ProcessResultWithTries {
            
            guard !DebugVariable.simulateError else {
                sleep(1)
                return .failure(PhantomError.requiredMiddlewareNoEffect(middleware: "SimulatedError"))
            }

            guard !DebugVariable.simulateMiddleware else {
                sleep(1)
                return .success((post: post, triesLeft: strategy.maxRetryCount))
            }
            
            var currentStrategy = strategy
            var processedPost = post
            var triesLeft: Int?
            
            for middleware in middlewares {
                let oneProcessResult = oneProcessPost(processedPost, using: middleware, strategy: currentStrategy)
                switch oneProcessResult {
                case .success((let processedPost_, let triesLeft_)):
                    processedPost = processedPost_
                    triesLeft = triesLeft_
                    
                    currentStrategy = DelayRetryStrategy(maxRetryCount: triesLeft_, retryInterval: currentStrategy.retryInterval)
                case .failure(let error):
                    return .failure(error)
                }
            }
            
            let postWithTries = (post: processedPost, triesLeft: triesLeft!)
            return .success(postWithTries)
        }
        
        private static func oneProcessPost(_ post: Post, using middleware: RequiredMiddleware, strategy: DelayRetryStrategy) -> ProcessResultWithTries {
            var retryCount = 0
            var lastError: Error?
            
            while retryCount < strategy.maxRetryCount {
                if retryCount > 0 {
                    Log.p("Attempt #\(retryCount + 1)")
                }
                
                let oneProcessResult = oneProcessPost(post, using: middleware)
                switch oneProcessResult {
                case .success(let post):
                    let resultWithTries = (post: post, triesLeft: strategy.maxRetryCount - retryCount)
                    return .success(resultWithTries)
                case .failure(let error):
                    lastError = error
                    retryCount += 1
                    
                    if let retryInterval = strategy.retryInterval {
                        Log.p("Waiting...")
                        Thread.sleep(forTimeInterval: retryInterval)
                        Log.p("Done waiting")
                    }
                }
            }
            
            return .failure(lastError!)
        }
        
        private static func oneProcessPost(_ post: Post, using middleware: RequiredMiddleware) -> ProcessResult {
            let processedPost: Post
            
            do {
                let middlewared = try middleware.transform(post: post)
                
                processedPost = middlewared.post
                let postChanged = middlewared.changed
                
                if middleware.isRequired && !postChanged {
                    throw PhantomError.requiredMiddlewareNoEffect(middleware: String(describing: middleware.middleware))
                }
            } catch {
                Log.p("Unexpected error while one processing", error)
                return .failure(error)
            }
            
            return .success(processedPost)
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
    
    func submitPost(_ post: Post, with params: SubmitParams, callback: @escaping SubmitCallback) { // todo: disable submission while signed out
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
