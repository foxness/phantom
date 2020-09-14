//
//  ZombieSubmitter.swift
//  Phantom
//
//  Created by Rivershy on 2020/09/13.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation

struct ZombieSubmitter {
    static let NOTIFICATION_WOKE_UP = Notification.Name("zombieWokeUp")
    static let NOTIFICATION_SUBMITTED = Notification.Name("zombieSubmittedFromBeyondTheGrave")
    static let NOTIFICATION_FAILED = Notification.Name("zombieFailed")
    
    private static let KEY_POST_ID = "postId"
    
    private init() { }
    
    static func submitPost(postId: UUID, callback: @escaping () -> Void) {
        notifyZombieWokeUp(postId: postId)
        
        let database = Database.instance
        
        guard let postIndex = database.posts.firstIndex(where: { $0.id == postId }) else {
            // if we get to this situation it means:
            // - the notification banner popped up
            // - the user deleted the post of the notification in app while the notification banned was still popped up
            // - the user pressed on the submit button of the notification banner while it was still popped up
            // the popped up notification banner can't be removed by removing the notification upon post deletion
            // post deletion removes the notification only in the notification center
            // so we have to account for that niche situation here
            
            Log.p("post wasnt found")
            notifyZombieFailed(postId: postId)
            callback()
            return
        }
        
        let post = database.posts[postIndex]
        
        let submitter = PostSubmitter.instance
        let reddit: Reddit!
        
        if submitter.reddit == nil {
            let redditAuth = database.redditAuth!
            reddit = Reddit(auth: redditAuth)
            submitter.reddit = reddit
        } else {
            reddit = submitter.reddit
        }
        
        submitter.submitPost(post) { url in
            let success = url != nil
            Log.p("success", success)
            Log.p("url", url)
            
            if success {
                database.posts.remove(at: postIndex)
                database.savePosts()
                
                let redditAuth = reddit.auth
                database.redditAuth = redditAuth
                
                notifyZombieSubmitted(postId: postId)
            } else {
                notifyZombieFailed(postId: postId)
                // todo: issue submission error user notification
            }
            
            callback()
        }
    }
    
    static func getPostId(notification: Notification) -> UUID {
        return notification.userInfo![KEY_POST_ID]! as! UUID
    }
    
    private static func notify(name: Notification.Name, postId: UUID) {
        let userInfo = [KEY_POST_ID: postId]
        NotificationCenter.default.post(name: name, object: nil, userInfo: userInfo)
    }
    
    private static func notifyZombieWokeUp(postId: UUID) {
        notify(name: NOTIFICATION_WOKE_UP, postId: postId)
    }
    
    private static func notifyZombieSubmitted(postId: UUID) {
        notify(name: NOTIFICATION_SUBMITTED, postId: postId)
    }
    
    private static func notifyZombieFailed(postId: UUID) { // todo: utilize this
        notify(name: NOTIFICATION_FAILED, postId: postId)
    }
}
