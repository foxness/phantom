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
    struct ContentParams {
        let title: String
        let body: String
        let subtitle: String?
        let userInfo: [AnyHashable: Any]?
        let categoryId: String?
        let sound: UNNotificationSound?
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
    
    static func requestPermissions(callback: @escaping (Bool, Error?) -> Void) {
        center.requestAuthorization(options: [.alert, .sound, .badge], completionHandler: callback)
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
        
        return content
    }
    
    private static func makeNowTrigger() -> UNNotificationTrigger {
        UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
    }
    
    private static func makeTrigger(for dateComponents: DateComponents) -> UNNotificationTrigger {
        UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
    }
    
    private static func makeRequest(params: RequestParams) -> UNNotificationRequest {
        let id = params.id
        let content = makeContent(params: params.content)
        let trigger = makeTrigger(for: params.dc)
        //let trigger = makeNowTrigger()
        
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
}
