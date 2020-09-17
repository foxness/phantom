//
//  PostNotifier.swift
//  Phantom
//
//  Created by Rivershy on 2020/09/11.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation
import UIKit

// todo: remove postscheduler?
// todo: revoke backgroundtasks persmissions?

struct PostNotifier {
    static let NOTIFICATION_ZOMBIE_WOKE_UP = ZombieSubmitter.NOTIFICATION_WOKE_UP
    static let NOTIFICATION_ZOMBIE_SUBMITTED = ZombieSubmitter.NOTIFICATION_SUBMITTED
    static let NOTIFICATION_ZOMBIE_FAILED = ZombieSubmitter.NOTIFICATION_FAILED
    
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
        
        switch actionId {
        case ACTION_SUBMIT:
            ZombieSubmitter.instance.submitPost(id: postId, callback: callback)
        case UNNotificationDefaultActionIdentifier:
            break
        default:
            fatalError()
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
    
    static func getPostId(notification: Notification) -> UUID {
        return ZombieSubmitter.getPostId(notification: notification)
    }
    
    private static func dateToComponents(_ date: Date) -> DateComponents {
        Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
    }
}
