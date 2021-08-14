//
//  PostSubmission.swift
//  Phantom
//
//  Created by River on 2021/06/19.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

// todo: add isPostImagePost check in PostTable.onSubmit instead of here if wallpapermode is on?

class PostSubmission: Operation {
    private typealias ProcessResult = Result<MiddlewarePost, Error>
    private typealias InternalProcessResultWithTries = Result<(post: MiddlewarePost, triesLeft: Int), Error>
    private typealias ProcessResultWithTries = Result<(post: Post, triesLeft: Int), Error>
    
    private let reddit: Reddit
    private let post: Post
    private let callback: PostSubmitter.SubmitCallback
    private let middlewares: [RequiredMiddleware]
    private let params: PostSubmitter.SubmitParams
    private let retryStrategy: RetryStrategy
    
    init(reddit: Reddit,
         post: Post,
         params: PostSubmitter.SubmitParams,
         imgur: Imgur? = nil,
         callback: @escaping PostSubmitter.SubmitCallback) {
        
        self.reddit = reddit
        self.post = post
        self.callback = callback
        self.params = params
        self.retryStrategy = DebugVariable.disableRetry ? .noRetry : .delay(delayRetryStrategy: DelayRetryStrategy(maxRetryCount: 5, retryInterval: 3))
        
        self.middlewares = PostSubmission.getMiddlewares(params: params, imgur: imgur)
    }
    
    private static func getMiddlewares(params: PostSubmitter.SubmitParams, imgur: Imgur?) -> [RequiredMiddleware] {
        var mw = [RequiredMiddleware]()
        
        if params.useWallhaven {
            let wallhavenMw = RequiredMiddleware(middleware: WallhavenMiddleware(), isRequired: true)
            mw.append(wallhavenMw)
        }
        
        if params.useImgur {
            if let imgur = imgur {
                let imgurMw = ImgurMiddleware(imgur,
                                              directUpload: DebugVariable.directImgurUpload,
                                              extractImageDimensions: params.wallpaperMode)
                
                let imgurRmw = RequiredMiddleware(middleware: imgurMw, isRequired: params.wallpaperMode)
                mw.append(imgurRmw)
            } else {
                fatalError("Imgur account required")
            }
        } else if params.wallpaperMode {
            let imageDimensionMw = ImageDimensionMiddleware()
            let imageDimensionRmw = RequiredMiddleware(middleware: imageDimensionMw, isRequired: true)
            mw.append(imageDimensionRmw)
        }
        
        if params.wallpaperMode {
            let wallpaperModeMw = WallpaperModeMiddleware()
            let wallpaperModeRmw = RequiredMiddleware(middleware: wallpaperModeMw, isRequired: true)
            mw.append(wallpaperModeRmw)
        }
        
        return mw
    }
    
    override func main() {
        guard !isCancelled else { return } // we need more of these in this method (actually everywhere in this class)
        
        Log.p("submission task started")
        
        let submitResult = processAndSubmit(retryStrategy: retryStrategy)
        callback(submitResult)
    }
    
    private func processAndSubmit(retryStrategy: RetryStrategy) -> PostSubmitter.SubmitResult {
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
        
        let sendReplies = params.sendReplies
        let submitResult = PostSubmission.submitPost(processedPost,
                                                     using: reddit,
                                                     sendReplies: sendReplies,
                                                     strategy: updatedStrategy)
        return submitResult
    }
    
    private static func submitPost(_ post: Post,
                                   using reddit: Reddit,
                                   sendReplies: Bool,
                                   strategy: DelayRetryStrategy) -> PostSubmitter.SubmitResult {
        var retryCount = 0
        var lastError: Error?
        
        while retryCount < strategy.maxRetryCount {
            if retryCount > 0 {
                Log.p("Attempt #\(retryCount + 1)")
            }
            
            let submitResult = submitPost(post, using: reddit, sendReplies: sendReplies)
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
    
    private static func submitPost(_ post: Post, using reddit: Reddit, sendReplies: Bool) -> PostSubmitter.SubmitResult {
        guard !DebugVariable.simulateReddit else {
            sleep(1)
            
            return .success("https://simulated-url-lolz.com/")
        }
        
        let url: PostSubmitter.RedditPostUrl
        do {
            // todo: send isCancelled closure into reddit.submit() so that it can check that at every step
            url = try reddit.submit(post: post, sendReplies: sendReplies)
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
        
        guard !middlewares.isEmpty else {
            return .success((post: post, triesLeft: strategy.maxRetryCount))
        }
        
        var currentStrategy = strategy
        var processedPost = MiddlewarePost(post: post)
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
        
        let postWithTries = (post: processedPost.post, triesLeft: triesLeft!)
        return .success(postWithTries)
    }
    
    private static func oneProcessPost(_ post: MiddlewarePost,
                                       using middleware: RequiredMiddleware,
                                       strategy: DelayRetryStrategy) -> InternalProcessResultWithTries {
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
    
    private static func oneProcessPost(_ post: MiddlewarePost, using middleware: RequiredMiddleware) -> ProcessResult {
        let processedPost: MiddlewarePost
        
        do {
            let middlewared = try middleware.transform(mwp: post)
            
            processedPost = middlewared.mwp
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
