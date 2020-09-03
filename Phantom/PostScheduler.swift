//
//  PostScheduler.swift
//  Phantom
//
//  Created by user179800 on 9/2/20.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation
//import Schedule
import BackgroundTasks

struct PostScheduler {
    static let TASK_REDDIT_POST_SUBMISSION = "redditPostSubmissionTask"
    
//    var task: Task?
    
    /*mutating func scheduleTask() {
        let work = {
            PostScheduler.doWork()
        }
        
        let plan = Plan.after(10.seconds)
        task = plan.do(action: work)
    }
    
    static func doWork() {
        sendNotification()
    }*/
    
    static func sendNotification() {
        let notification = Notifications.make(title: "hello there, I'm doing work", body: "asd")
        Notifications.send(notification)
    }
    
    static func registerPostTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: PostScheduler.TASK_REDDIT_POST_SUBMISSION, using: nil) { task in
            PostScheduler.performPostTask(task as! BGProcessingTask)
        }
    }
    
    static func schedulePostTask() {
        let request = BGProcessingTaskRequest(identifier: PostScheduler.TASK_REDDIT_POST_SUBMISSION)
        request.requiresNetworkConnectivity = true
        request.earliestBeginDate = Date(timeIntervalSinceNow: 10)
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    static func performPostTask(_ task: BGProcessingTask) {
        /*
        let operation = Operation() // next todo: inherit from operation
        
        task.expirationHandler = {
            operation.cancel()
        }
        
        operation.completionBlock = {
            task.setTaskCompleted(success: !operation.isCancelled)
        }
        
        operationQueue.addOperation(operation) // next todo: get operation queue from somewhere
        */
    }
}
