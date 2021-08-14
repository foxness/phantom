//
//  PostSubmitter.swift
//  Phantom
//
//  Created by Rivershy on 2020/09/03.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation

// todo: make post submitter non-singleton now that there's no zombiesubmitter?
// todo: make reddit & imgur properties non-atomic (only after making it non-singleton)

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
    
    private func addSubmissionToQueue(_ submission: PostSubmission) {
        submission.completionBlock = {
            guard !submission.isCancelled else { return }
            
            Log.p("submission task complete")
        }
        
        submitQueue.addOperation(submission)
    }
    
    func submitPost(_ post: Post, with params: SubmitParams, callback: @escaping SubmitCallback) {
        guard let reddit = reddit.value else { fatalError("Reddit account not found") }
        
        let imgur = imgur.value
        let submission = PostSubmission(reddit: reddit,
                                        post: post,
                                        params: params,
                                        imgur: imgur,
                                        callback: callback)
        
        addSubmissionToQueue(submission)
    }
    
    func cancelEverything() {
        submitQueue.cancelAllOperations()
    }
    
    private static func getSubmitQueue() -> OperationQueue {
        let queue = OperationQueue()
        queue.name = "Submit queue"
        queue.maxConcurrentOperationCount = 1
        
        return queue
    }
}
