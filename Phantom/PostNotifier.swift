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
    private static let ACTION_SUBMIT = "submit"
    private static let CATEGORY_DUE_POST = "duePost"
    private static let TITLE_SUBMIT_ACTION = "Submit Post"
    
    private init() { }
    
    static func notify(for post: Post) {
        let date = post.date
        guard date > Date() else { return }
        
        let title = post.title
        let body = "Time to submit has come"
        let subtitle: String? = nil
        //let userInfo = ["postId": post.id]
        //let categoryId = CATEGORY_DUE_POST
        let sound = UNNotificationSound.default
        
        let id = post.id.uuidString
        let dc = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        
        let content = Notifications.ContentParams(title: title, body: body, subtitle: subtitle, userInfo: nil, categoryId: nil, sound: sound)
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
    }
    
    static func getNotificationCategory() -> UNNotificationCategory {
        let actionIdentifier = ACTION_SUBMIT
        let actionTitle = TITLE_SUBMIT_ACTION
        let actionOptions: UNNotificationActionOptions = []
        
        let submitAction = UNNotificationAction(identifier: actionIdentifier,
                                                title: actionTitle,
                                                options: actionOptions)
        
        let categoryIdentifier = CATEGORY_DUE_POST
        let categoryActions = [submitAction]
        let categoryIntents: [String] = []
        let categoryPlaceholder = ""
        let categoryOptions: UNNotificationCategoryOptions = [.allowAnnouncement]
        
        let duePostCategory = UNNotificationCategory(identifier: categoryIdentifier,
                                                     actions: categoryActions,
                                                     intentIdentifiers: categoryIntents,
                                                     hiddenPreviewsBodyPlaceholder: categoryPlaceholder,
                                                     options: categoryOptions)
        
        return duePostCategory
    }
}
