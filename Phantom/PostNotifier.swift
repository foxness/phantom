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
    private static let INFO_POST_ID = "postID"
    
    private init() { }
    
    static func notify(for post: Post) {
        let date = post.date
        guard date > Date() else { return }
        
        let title = post.title
        let body = "Time to submit has come"
        let subtitle: String? = nil
        let userInfo = [INFO_POST_ID: post.id.uuidString]
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
    }
    
    static func didReceiveResponse(_ response: UNNotificationResponse, callback: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        let postIdString = userInfo[INFO_POST_ID] as! String
        let postId = UUID(uuidString: postIdString)!
        
        let actionId = response.actionIdentifier
        assert(actionId == ACTION_SUBMIT)
        
        submitPost(postId: postId, callback: callback)
    }
    
    // submit from beyond the grave
    private static func submitPost(postId: UUID, callback: @escaping () -> Void) {
        let database = Database.instance
        let refreshToken = database.redditRefreshToken
        let accessToken = database.redditAccessToken
        let accessTokenExpirationDate = database.redditAccessTokenExpirationDate
        let post = database.posts.first { $0.id == postId }!
        
        let reddit = Reddit(refreshToken: refreshToken, accessToken: accessToken, accessTokenExpirationDate: accessTokenExpirationDate)
        var submitter = PostSubmitter(reddit: reddit)
        
        submitter.submitPost(post) { url in
            let success = url != nil
            Log.p("success", success)
            Log.p("url", url)
            callback()
        }
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
    
    private static func dateToComponents(_ date: Date) -> DateComponents {
        Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
    }
}
