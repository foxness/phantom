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
        
        // DEBUGVAR
        let simulateSubmission = false
        
        init(reddit: Reddit, database: Database, callback: @escaping UrlCallback) {
            self.reddit = reddit
            self.post = PostSubmission.getPost(database: database)
            self.callback = callback
        }
        
        init(reddit: Reddit, post: Post, callback: @escaping UrlCallback) {
            self.reddit = reddit
            self.post = post
            self.callback = callback
        }
        
        private static func getPost(database: Database) -> Post {
            return database.posts.last!
        }
        
        override func main() {
            guard !isCancelled else { return }
            
            Log.p("submission task started")
            
            // why use dispatch group?
            // to make reddit async tasks sync
            // so that it works nicely with operation queue (correctly adheres to maxConcurrentOperationCount)
            
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            
            if simulateSubmission {
                DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 3) {
                    guard !self.isCancelled else { return }
                    self.callback("https://simulated-url-lolz.com/")
                    dispatchGroup.leave()
                }
            } else {
                // todo: send isCancelled closure into reddit.submit() so that it can check that at every step
                reddit.submit(post: post) { url in
                    guard !self.isCancelled else { return }
                    self.callback(url)
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.wait()
        }
    }
    
    static let instance = PostSubmitter()
    
    var reddit = Atomic<Reddit?>(nil)
    
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
        guard let reddit = reddit.value else { fatalError() }
        
        let submission = PostSubmission(reddit: reddit, post: post, callback: callback)
        addToQueue(submission: submission)
    }
    
    func submitPostInDatabase(_ database: Database, callback: @escaping UrlCallback) {
        guard let reddit = reddit.value else { fatalError() }
        
        let submission = PostSubmission(reddit: reddit, database: database, callback: callback)
        addToQueue(submission: submission)
    }
    
    func cancelEverything() {
        submitQueue.cancelAllOperations()
    }
}
