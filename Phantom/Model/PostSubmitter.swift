//
//  PostSubmitter.swift
//  Phantom
//
//  Created by Rivershy on 2020/09/03.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation

class PostSubmitter {
    typealias SubmitCallback = (_ url: String?, _ error: Error?) -> Void
    
    private class PostSubmission: Operation {
        private let reddit: Reddit
        private let post: Post
        private let callback: SubmitCallback
        private let middlewares: [SubmitterMiddleware]
        
        // DEBUGVAR
        let simulateReddit = false
        let simulateMiddleware = false
        
        init(reddit: Reddit,
             database: Database,
             imgur: Imgur? = nil,
             useWallhaven: Bool = true,
             callback: @escaping SubmitCallback) {
            self.reddit = reddit
            self.post = PostSubmission.getPost(database: database)
            self.callback = callback
            self.middlewares = PostSubmission.getMiddlewares(useWallhaven: useWallhaven, imgur: imgur)
        }
        
        init(reddit: Reddit,
             post: Post,
             imgur: Imgur? = nil,
             useWallhaven: Bool = true,
             callback: @escaping SubmitCallback) {
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
        
        private func executeMiddlewares(on post: Post) throws -> Post {
            guard !simulateMiddleware else {
                sleep(1)
                return post
            }
            
            var middlewaredPost = post
            for middleware in middlewares {
                let middlewared = try middleware.transform(post: middlewaredPost)
                
                middlewaredPost = middlewared.post
                let postChanged = middlewared.changed
                
                if !postChanged {
                    throw SubmitterError.noEffectMiddleware(middleware: String(describing: middleware))
                }
                
                // todo: handle imgur 10 MB error
            }
            
            return middlewaredPost
        }
        
        private func submitPost(_ post: Post) throws -> String {
            guard !simulateReddit else {
                sleep(3)
                
                return "https://simulated-url-lolz.com/"
            }
            
            // todo: send isCancelled closure into reddit.submit() so that it can check that at every step
            let url = try reddit.submit(post: post)
            return url
        }
        
        override func main() {
            guard !isCancelled else { return } // we need more of these in this method
            
            Log.p("submission task started")
            
            let middlewaredPost: Post
            do {
                middlewaredPost = try executeMiddlewares(on: post)
            } catch {
                Log.p("Unexpected error while middlewaring", error)
                callback(nil, error)
                return
            }
            
            guard !isCancelled else { return }
            
            let url: String
            do {
                url = try submitPost(middlewaredPost)
            } catch {
                Log.p("Unexpected error while submitting", error)
                callback(nil, error)
                return
            }
            
            callback(url, nil)
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
    
    func submitPost(_ post: Post, callback: @escaping SubmitCallback) {
        guard let reddit = reddit.value,
              let imgur = imgur.value
        else {
            fatalError()
        }
        
        let submission = PostSubmission(reddit: reddit, post: post, imgur: imgur, callback: callback)
        addToQueue(submission: submission)
    }
    
    func submitPostInDatabase(_ database: Database, callback: @escaping SubmitCallback) {
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

enum SubmitterError: Error {
    case noEffectMiddleware(middleware: String)
}
