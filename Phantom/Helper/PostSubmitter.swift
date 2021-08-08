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
        let useImgur: Bool
        let wallpaperMode: Bool
        let useWallhaven: Bool
        let sendReplies: Bool
    }
    
    static let instance = PostSubmitter()
    
    var reddit = Atomic<Reddit?>(nil)
    var imgur = Atomic<Imgur?>(nil)
    
    private lazy var submitQueue = PostSubmitter.getSubmitQueue()
    
    private init() { }
    
    private func addToQueue(submission: PostSubmission) {
        submission.completionBlock = {
            guard !submission.isCancelled else { return }
            
            Log.p("submission task complete")
        }
        
        submitQueue.addOperation(submission)
    }
    
    func submitPost(_ post: Post, with params: SubmitParams, callback: @escaping SubmitCallback) { // todo: disable submission while signed out
        submitPostInternal(post: post, database: nil, params: params, callback: callback)
    }
    
    func submitPostInDatabase(_ database: Database, with params: SubmitParams, callback: @escaping SubmitCallback) { // todo: get rid of zombiesubmitter and this method?
        submitPostInternal(post: nil, database: database, params: params, callback: callback)
    }
    
    func cancelEverything() {
        submitQueue.cancelAllOperations()
    }
    
    private func submitPostInternal(post: Post?, database: Database?, params: SubmitParams, callback: @escaping SubmitCallback) {
        guard let reddit = reddit.value else { fatalError("Reddit account not found") }
        
        let imgur = imgur.value
        
        let submission: PostSubmission
        if let post = post {
            submission = PostSubmission(reddit: reddit,
                                        post: post,
                                        params: params,
                                        imgur: imgur,
                                        callback: callback)
        } else if let database = database {
            submission = PostSubmission(reddit: reddit,
                                        database: database,
                                        params: params,
                                        imgur: imgur,
                                        callback: callback)
        } else {
            fatalError("Either post or database must be passed to this method")
        }
        
        addToQueue(submission: submission)
    }
    
    private static func getSubmitQueue() -> OperationQueue {
        let queue = OperationQueue()
        queue.name = "Submit queue"
        queue.maxConcurrentOperationCount = 1
        
        return queue
    }
}
