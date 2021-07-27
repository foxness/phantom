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
    
    static let NOTIFICATION_SUBMIT_REQUESTED = Notification.Name("SubmitRequested")
    
    private static let ACTION_SUBMIT = "submit"
    private static let ACTION_SUBMIT_TEST = "submitTest" // todo: remove
    
    private static let TITLE_SUBMIT_ACTION = "Submit Post"
    private static let TITLE_SUBMIT_ACTION_TEST = "Submit Post Test" // todo: remove
    
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
            notifyAppSubmitRequested(postId: postId)
        
        case ACTION_SUBMIT_TEST:
//            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            Log.p("action is submit test")
            if let navVC = window?.rootViewController as? UINavigationController {
                Log.p("root is navvc")
                
                if let postTableVC = navVC.viewControllers.first as? PostTableViewController {
                    Log.p("it works")
                    postTableVC.displayOkAlert(title: "it works", message: "yay: \(postIdString)")
                }
            }
               
            
//            // instantiate the view controller we want to show from storyboard
//            // root view controller is tab bar controller
//            // the selected tab is a navigation controller
//            // then we push the new view controller to it
//            if  let conversationVC = storyboard.instantiateViewController(withIdentifier: "ConversationViewController") as? ConversationViewController,
//                let tabBarController = self.window?.rootViewController as? UITabBarController,
//                let navController = tabBarController.selectedViewController as? UINavigationController {
//
//                // we can modify variable of the new view controller using notification data
//                // (eg: title of notification)
//                conversationVC.senderDisplayName = response.notification.request.content.title
//                // you can access custom data of the push notification by using userInfo property
//                // response.notification.request.content.userInfo
//                navController.pushViewController(conversationVC, animated: true)
//            }
            
        case UNNotificationDefaultActionIdentifier: break
        default: fatalError("Unexpected notification action")
        }
        
        callback()
    }
    
    static func getDuePostCategory() -> UNNotificationCategory {
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
    
    static func getDuePostCategoryTest() -> UNNotificationCategory {
        let actionId = ACTION_SUBMIT
        let actionTitle = TITLE_SUBMIT_ACTION
        let actionOptions: UNNotificationActionOptions = [.foreground]
        
        let submitAction = UNNotificationAction(identifier: actionId,
                                                title: actionTitle,
                                                options: actionOptions)
        
        let actionIdTest = ACTION_SUBMIT_TEST
        let actionTitleTest = TITLE_SUBMIT_ACTION_TEST
        let actionOptionsTest: UNNotificationActionOptions = [.foreground]
        
        let submitActionTest = UNNotificationAction(identifier: actionIdTest,
                                                    title: actionTitleTest,
                                                    options: actionOptionsTest)
        
        let categoryId = CATEGORY_DUE_POST
        let categoryActions = [submitAction, submitActionTest]
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
    
    private static func notifyApp(name: Notification.Name, postId: UUID) { // todo: extract into helper?
        let userInfo = [KEY_POST_ID: postId]
        NotificationCenter.default.post(name: name, object: nil, userInfo: userInfo)
    }
    
    private static func notifyAppSubmitRequested(postId: UUID) {
        notifyApp(name: NOTIFICATION_SUBMIT_REQUESTED, postId: postId)
    }
    
    private static func dateToComponents(_ date: Date) -> DateComponents {
        Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
    }
}
