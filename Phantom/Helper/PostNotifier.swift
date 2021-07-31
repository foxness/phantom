//
//  PostNotifier.swift
//  Phantom
//
//  Created by Rivershy on 2020/09/11.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation
import UIKit

struct PostNotifier {
    static let NOTIFICATION_ZOMBIE_WOKE_UP = ZombieSubmitter.NOTIFICATION_WOKE_UP
    static let NOTIFICATION_ZOMBIE_SUBMITTED = ZombieSubmitter.NOTIFICATION_SUBMITTED
    static let NOTIFICATION_ZOMBIE_FAILED = ZombieSubmitter.NOTIFICATION_FAILED
    
    private static let ACTION_SUBMIT = "submit"
    private static let TITLE_SUBMIT_ACTION = "Submit Post"
    private static let CATEGORY_DUE_POST = "duePost"
    private static let KEY_POST_ID = "postId"
    
    private init() { }
    
    static func notifyUser(about post: Post) {
        let date = post.date
        guard date > Date() else { return } // todo: dont notify if post is due in less than 1 min
        
        let postId = post.id.uuidString
        let postDate = dateToComponents(date)
        
        let title = post.title
        let body = "Time to submit has come"
        let subtitle: String? = nil
        let userInfo = [KEY_POST_ID: postId]
        let categoryId = CATEGORY_DUE_POST
        let sound = UNNotificationSound.default
        let badgeCount = 1
        
        let content = Notifications.ContentParams(title: title, body: body, subtitle: subtitle, userInfo: userInfo, categoryId: categoryId, sound: sound, badgeCount: badgeCount)
        let params = Notifications.RequestParams(id: postId, dc: postDate, content: content)
        
        Notifications.request(params: params) { error in
            if let error = error {
                Log.p("notify error", error)
            }
        }
    }
    
    static func cancel(for post: Post) {
        let id = post.id.uuidString
        Notifications.cancel(ids: id)
        Notifications.removeDelivered(ids: id)
    }
    
    static func updateAppBadge(posts: [Post]) {
        // this cancels out the brief period of time after notification comes but date isn't overdue yet
        // the notification doesn't come right on time (just calendar trigger things I guess) so we give it 1 min leeway
        
        // alternatively we can check if there are delivered notifications
        // and if there are, set the app badge to 1 regardless [todo]
        
        let leeway = TimeInterval(60) // 1 min
        let now = Date()
        let adjustedNow = now + leeway
        let overdueCount = posts.count { $0.date < adjustedNow }
        let badgeCount = overdueCount == 0 ? 0 : 1
        
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = badgeCount // todo: use overdue count instead
        }
    }
    
    static func didReceiveResponse(_ response: UNNotificationResponse, window: UIWindow?, callback: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        let postIdString = userInfo[KEY_POST_ID] as! String
        let postId = UUID(uuidString: postIdString)!
        let actionId = response.actionIdentifier
        
        switch actionId {
        case ACTION_SUBMIT:
            // the thing that helped me a frickton with this: https://fluffy.es/open-specific-view-push-notification-tapped/
            
            if let navVC = window?.rootViewController as? UINavigationController,
               let postTableVC = navVC.viewControllers.first as? PostTableViewController {
                postTableVC.submitRequestedFromUserNotification(postId: postId)
            }
            
        case UNNotificationDefaultActionIdentifier:
            break
            
        default:
            fatalError("Unexpected notification action")
        }
        
        callback()
    }
    
    static func getNotificationCategories() -> Set<UNNotificationCategory> {
        return [getDuePostCategory()]
    }
    
    private static func getDuePostCategory() -> UNNotificationCategory {
        let actionId = ACTION_SUBMIT
        let actionTitle = TITLE_SUBMIT_ACTION
        let actionOptions: UNNotificationActionOptions = [.foreground]
        
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
