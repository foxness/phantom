//
//  PostSubmitter.swift
//  Phantom
//
//  Created by user179800 on 9/3/20.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation

struct PostSubmitter {
    typealias UrlCallback = (String?) -> Void
    
    private class PostSubmission: Operation {
        private let reddit: Reddit
        private let post: Post
        private let callback: UrlCallback
        
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
            let title = database.postTitle
            let text = database.postText
            let subreddit = database.postSubreddit
            
            let post = Post(title: title, content: text, subreddit: subreddit)
            return post
        }
        
        override func main() {
            guard !isCancelled else { return }
            
            // todo: send isCancelled closure into reddit.submit() so that it can check that at every step
            reddit.submit(post: post) { url in
                guard !self.isCancelled else { return }
                self.callback(url)
            }
        }
    }
    
    let reddit: Reddit
    
    private lazy var submitQueue: OperationQueue = PostSubmitter.getSubmitQueue()
    
    private static func getSubmitQueue() -> OperationQueue {
        let queue = OperationQueue()
        queue.name = "Submit queue"
        queue.maxConcurrentOperationCount = 1
        
        return queue
    }
    
    init(reddit: Reddit) {
        self.reddit = reddit
    }
    
    private mutating func addToQueue(submission: PostSubmission) {
        submission.completionBlock = {
            guard !submission.isCancelled else { return }
            
            Log.p("submission complete")
        }
        
        submitQueue.addOperation(submission)
    }
    
    mutating func submitPost(_ post: Post, callback: @escaping UrlCallback) {
        let submission = PostSubmission(reddit: reddit, post: post, callback: callback)
        addToQueue(submission: submission)
    }
    
    mutating func submitPostInDatabase(_ database: Database, callback: @escaping UrlCallback) {
        let submission = PostSubmission(reddit: reddit, database: database, callback: callback)
        addToQueue(submission: submission)
    }
    
    mutating func cancelEverything() {
        submitQueue.cancelAllOperations()
    }
}
