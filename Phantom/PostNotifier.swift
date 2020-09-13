//
//  PostNotifier.swift
//  Phantom
//
//  Created by user179838 on 9/11/20.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation
import UIKit

struct PostNotifier {
    static let NOTIFICATION_ZOMBIE_WOKE_UP = Notification.Name("zombieWokeUp")
    static let NOTIFICATION_ZOMBIE_SUBMITTED = Notification.Name("zombieSubmittedFromBeyondTheGrave")
    static let NOTIFICATION_ZOMBIE_FAILED = Notification.Name("zombieFailed")
    
    private static let ACTION_SUBMIT = "submit"
    private static let CATEGORY_DUE_POST = "duePost"
    private static let TITLE_SUBMIT_ACTION = "Submit Post"
    private static let KEY_POST_ID = "postId"
    
    private init() { }
    
    static func notifyUser(about post: Post) {
        let date = post.date
        guard date > Date() else { return }
        
        let title = post.title
        let body = "Time to submit has come"
        let subtitle: String? = nil
        let userInfo = [KEY_POST_ID: post.id.uuidString]
        let categoryId = CATEGORY_DUE_POST
        let sound = UNNotificationSound.default
        
        let id = post.id.uuidString
        let dc = dateToComponents(date)
        
        let content = Notifications.ContentParams(title: title, body: body, subtitle: subtitle, userInfo: userInfo, categoryId: categoryId, sound: sound)
        let params = Notifications.RequestParams(id: id, dc: dc, content: content)
        
        Notifications.request(params: params) { error in
            if let error = error {
                Log.p("notify error", error)
            } else {
                Log.p("notification scheduled")
            }
        }
    }
    
    static func cancel(for post: Post) {
        let id = post.id.uuidString
        Notifications.cancel(ids: id)
        Notifications.removeDelivered(ids: id)
    }
    
    static func didReceiveResponse(_ response: UNNotificationResponse, callback: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        let postIdString = userInfo[KEY_POST_ID] as! String
        let postId = UUID(uuidString: postIdString)!
        
        let actionId = response.actionIdentifier
        assert(actionId == ACTION_SUBMIT) // todo: handle just opening the up instead of crashing
        
        submitPost(postId: postId, callback: callback)
    }
    
    static func getPostId(zombieNotification: Notification) -> UUID {
        return zombieNotification.userInfo![KEY_POST_ID]! as! UUID
    }
    
    private static func notify(name: Notification.Name, postId: UUID) {
        let userInfo = [KEY_POST_ID: postId]
        NotificationCenter.default.post(name: name, object: nil, userInfo: userInfo)
    }
    
    private static func notifyZombieWokeUp(postId: UUID) {
        notify(name: NOTIFICATION_ZOMBIE_WOKE_UP, postId: postId)
    }
    
    private static func notifyZombieSubmitted(postId: UUID) {
        notify(name: NOTIFICATION_ZOMBIE_SUBMITTED, postId: postId)
    }
    
    private static func notifyZombieFailed(postId: UUID) { // todo: utilize this
        notify(name: NOTIFICATION_ZOMBIE_FAILED, postId: postId)
    }
    
    // submit from beyond the grave
    private static func submitPost(postId: UUID, callback: @escaping () -> Void) {
        notifyZombieWokeUp(postId: postId)
        
        let database = Database.instance
        let redditAuth = database.redditAuth!
        
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
        
        let reddit = Reddit(auth: redditAuth)
        var submitter = PostSubmitter(reddit: reddit)
        
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
    
    static func getDuePostCategory() -> UNNotificationCategory {
        let actionId = ACTION_SUBMIT
        let actionTitle = TITLE_SUBMIT_ACTION
        let actionOptions: UNNotificationActionOptions = []
        
        let submitAction = UNNotificationAction(identifier: actionId,
                                                title: actionTitle,
                                                options: actionOptions)
        
        let categoryId = CATEGORY_DUE_POST
        let categoryActions = [submitAction]
        let categoryIntents: [String] = []
        let categoryPlaceholder = ""
        let categoryOptions: UNNotificationCategoryOptions = [.allowAnnouncement]
        
        let duePostCategory = UNNotificationCategory(identifier: categoryId,
                                                     actions: categoryActions,
                                                     intentIdentifiers: categoryIntents,
                                                     hiddenPreviewsBodyPlaceholder: categoryPlaceholder,
                                                     options: categoryOptions)
        
        return duePostCategory
    }
    
    private static func dateToComponents(_ date: Date) -> DateComponents {
        Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
    }
}
