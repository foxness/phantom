//
//  PostSubmitter.swift
//  Phantom
//
//  Created by Rivershy on 2020/09/03.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation

class PostSubmitter {
    typealias UrlCallback = (String?) -> Void
    
    private class PostSubmission: Operation {
        private let reddit: Reddit
        private let post: Post
        private let callback: UrlCallback
        private let middlewares: [SubmitterMiddleware]
        
        // DEBUGVAR
        let simulateReddit = true
        let simulateMiddleware = true
        
        init(reddit: Reddit,
             database: Database,
             imgur: Imgur? = nil,
             useWallhaven: Bool = true,
             callback: @escaping UrlCallback) {
            self.reddit = reddit
            self.post = PostSubmission.getPost(database: database)
            self.callback = callback
            self.middlewares = PostSubmission.getMiddlewares(useWallhaven: useWallhaven, imgur: imgur)
        }
        
        init(reddit: Reddit,
             post: Post,
             imgur: Imgur? = nil,
             useWallhaven: Bool = true,
             callback: @escaping UrlCallback) {
            self.reddit = reddit
            self.post = post
            self.callback = callback
            self.middlewares = PostSubmission.getMiddlewares(useWallhaven: useWallhaven, imgur: imgur)
        }
        
        private static func getMiddlewares(useWallhaven: Bool, imgur: Imgur?) -> [SubmitterMiddleware] {
            var mw = [SubmitterMiddleware]()
            
            if useWallhaven {
                mw.append(WallhavenMiddleware())
            }
            
            if let imgur = imgur {
                mw.append(ImgurMiddleware(imgur))
            }
            
            return mw
        }
        
        private static func getPost(database: Database) -> Post {
            return database.posts.last!
        }
        
        override func main() {
            guard !isCancelled else { return }
            
            Log.p("submission task started")
            
            var middlewaredPost = post
            if simulateMiddleware {
                sleep(1)
            } else {
                for middleware in middlewares {
                    middlewaredPost = middleware.transform(post: middlewaredPost)
                }
            }
            
            if simulateReddit {
                sleep(3)
                guard !self.isCancelled else { return }
                callback("https://simulated-url-lolz.com/")
            } else {
                // todo: send isCancelled closure into reddit.submit() so that it can check that at every step
                
                let url = try! reddit.submit(post: middlewaredPost)
                callback(url)
            }
        }
    }
    
    static let instance = PostSubmitter()
    
    var reddit = Atomic<Reddit?>(nil)
    var imgur = Atomic<Imgur?>(nil) // todo: incorporate into middleware
    
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
    
    func submitPost(_ post: Post, callback: @escaping UrlCallback) {
        guard let reddit = reddit.value,
              let imgur = imgur.value
        else {
            fatalError()
        }
        
        let submission = PostSubmission(reddit: reddit, post: post, imgur: imgur, callback: callback)
        addToQueue(submission: submission)
    }
    
    func submitPostInDatabase(_ database: Database, callback: @escaping UrlCallback) {
        guard let reddit = reddit.value,
              let imgur = imgur.value
        else {
            fatalError()
        }
        
        let submission = PostSubmission(reddit: reddit, database: database, imgur: imgur, callback: callback)
        addToQueue(submission: submission)
    }
    
    func cancelEverything() {
        submitQueue.cancelAllOperations()
    }
}
