//
//  PostScheduler.swift
//  Phantom
//
//  Created by user179800 on 9/2/20.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation

// !!!
//import Schedule
// !!!

import BackgroundTasks

// struct is impossible because performPostTask() requires mutating self in escaped closure

class PostScheduler {
    private static let TASK_REDDIT_POST_SUBMISSION = "redditPostSubmissionTask"
    
    private var submitter: PostSubmitter
    private let database: Database = .instance
    
    init?() {
        let refreshToken = database.redditRefreshToken
        let accessToken = database.redditAccessToken
        let accessTokenExpirationDate = database.redditAccessTokenExpirationDate
        
        if refreshToken == nil {
            Log.p("didnt find good reddit in database")
            return nil
        } else {
            let reddit = Reddit(refreshToken: refreshToken,
                            accessToken: accessToken,
                            accessTokenExpirationDate: accessTokenExpirationDate)
            
            submitter = PostSubmitter(reddit: reddit)
        }
    }
    
    //init(submitter: PostSubmitter) {
    //    self.submitter = submitter
    //}
    
    static func sendNotification() {
        let notification = Notifications.make(title: "hello there, I'm doing work", body: "asd")
        Notifications.send(notification)
    }
    
    static func registerPostTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: PostScheduler.TASK_REDDIT_POST_SUBMISSION, using: nil) { task in
            if let scheduler = PostScheduler() {
                scheduler.performPostTask(task as! BGProcessingTask)
            }
        }
    }
    
    static func schedulePostTask(earliestBeginDate: Date) {
        let request = BGProcessingTaskRequest(identifier: PostScheduler.TASK_REDDIT_POST_SUBMISSION)
        request.requiresNetworkConnectivity = true
        request.earliestBeginDate = earliestBeginDate
        
        do {
            // this throws an error when run on simulator
            try BGTaskScheduler.shared.submit(request)
        } catch {
            Log.p("Could not schedule processing task", error)
        }
    }
    
    private func performPostTask(_ task: BGProcessingTask) {
        task.expirationHandler = {
            self.submitter.cancelEverything()
        }
        
        submitter.submitPostInDatabase(database) { url in
            let success = url != nil
            task.setTaskCompleted(success: success)
            Log.p("submitted a post from beyond the grave")
            
            PostScheduler.sendNotification()
        }
    }
}
