//
//  Notifications.swift
//  Phantom
//
//  Created by Rivershy on 2020/09/02.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation
import UIKit

struct Notifications {
    struct ContentParams {
        let title: String
        let body: String
        let subtitle: String?
        let userInfo: [AnyHashable: Any]?
        let categoryId: String?
        let sound: UNNotificationSound?
        let badgeCount: Int?
        let isTimeSensitive: Bool
    }
    
    struct RequestParams {
        let id: String
        let dc: DateComponents
        let content: ContentParams
    }
    
    private static var center: UNUserNotificationCenter = .current()
    
    private init() { }
    
    private static func notificationsAllowed(callback: @escaping (Bool) -> Void) {
        center.getNotificationSettings { settings in
            let allowed = settings.authorizationStatus == .authorized
            callback(allowed)
        }
    }
    
    private static func runIfNotificationsAllowed(callback: @escaping () -> Void) {
        notificationsAllowed { allowed in
            guard allowed else { return }
            callback()
        }
    }
    
    // callback: (granted: Bool, error: Error?) -> Void
    static func requestPermissions(callback: @escaping (Bool, Error?) -> Void) {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        center.requestAuthorization(options: options, completionHandler: callback)
    }
    
    private static func makeContent(params: ContentParams) -> UNNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = params.title
        content.body = params.body
        
        if let subtitle = params.subtitle {
            content.subtitle = subtitle
        }
        
        if let userInfo = params.userInfo {
            content.userInfo = userInfo
        }
        
        if let categoryId = params.categoryId {
            content.categoryIdentifier = categoryId
        }
        
        if let sound = params.sound {
            content.sound = sound
        } else {
            content.sound = .default
        }
        
        if let badgeCount = params.badgeCount {
            content.badge = NSNumber(value: badgeCount)
        }
        
        if #available(iOS 15.0, *) {
            content.interruptionLevel = params.isTimeSensitive ? .timeSensitive : .active
        }
        
        return content
    }
    
    private static func makeNowTrigger() -> UNNotificationTrigger {
        UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
    }
    
    private static func makeTrigger(for dateComponents: DateComponents) -> UNNotificationTrigger {
        UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
    }
    
    private static func makeRequest(params: RequestParams) -> UNNotificationRequest {
        let id = params.id
        let content = makeContent(params: params.content)
        let trigger = AppVariables.Debug.instantNotifications ? makeNowTrigger() : makeTrigger(for: params.dc)
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        return request
    }
    
    private static func sendRequest(_ request: UNNotificationRequest, callback: ((Error?) -> Void)? = nil) {
        runIfNotificationsAllowed {
            center.add(request, withCompletionHandler: callback)
        }
    }
    
    static func request(params: RequestParams, callback: ((Error?) -> Void)? = nil) {
        let request = makeRequest(params: params)
        sendRequest(request, callback: callback)
    }
    
    static func cancel(ids: String...) {
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
    
    static func removeDelivered(ids: String...) {
        center.removeDeliveredNotifications(withIdentifiers: ids)
    }
}
