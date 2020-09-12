//
//  Notifications.swift
//  Phantom
//
//  Created by user179800 on 9/2/20.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation
import UIKit

struct Notifications {
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
    
    static func requestPermissions(callback: @escaping (Bool, Error?) -> Void) {
        center.requestAuthorization(options: [.alert, .sound, .badge], completionHandler: callback)
    }
    
    private static func makeContent(title: String, body: String) -> UNNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        
        return content
    }
    
    private static func makeNowTrigger() -> UNNotificationTrigger {
        UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
    }
    
    private static func makeTrigger(for dateComponents: DateComponents) -> UNNotificationTrigger {
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        return trigger
    }
    
    private static func makeRequest(id: String, content: UNNotificationContent, trigger: UNNotificationTrigger) -> UNNotificationRequest {
        UNNotificationRequest(identifier: id, content: content, trigger: trigger)
    }
    
    private static func makeRequest(id: String, title: String, body: String, dateComponents: DateComponents) -> UNNotificationRequest {
        let content = makeContent(title: title, body: body)
        let trigger = makeTrigger(for: dateComponents)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        return request
    }
    
    private static func sendRequest(_ request: UNNotificationRequest, callback: ((Error?) -> Void)? = nil) {
        runIfNotificationsAllowed {
            center.add(request, withCompletionHandler: callback)
        }
    }
    
    static func request(id: String, title: String, body: String, dateComponents: DateComponents, callback: ((Error?) -> Void)? = nil) {
        let request = makeRequest(id: id, title: title, body: body, dateComponents: dateComponents)
        sendRequest(request, callback: callback)
    }
    
    static func cancel(ids: String...) {
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}
