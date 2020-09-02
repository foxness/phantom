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
    static func runIfNotificationsAllowed(callback: @escaping () -> Void) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            callback()
        }
    }
    
    static func make(title: String = "Asdy title", body: String = "Asdy body") -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        //content.subtitle = "asdy sub"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        
        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(identifier: uuidString,
                                            content: content, trigger: trigger)
        
        return request
    }
    
    static func send(_ notification: UNNotificationRequest) {
        runIfNotificationsAllowed {
            let center = UNUserNotificationCenter.current()
            center.add(notification) { error in
                if error != nil {
                    Log.p("notif error", error)
                } else {
                    Log.p("no error")
                }
            }
            
            Log.p("notif request sent")
        }
    }
    
    static func requestPermissions(callback: @escaping () -> Void) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                Log.p("notifications error", error)
            }
            
            Log.p("notifications \(granted ? "" : "not ")granted")
            
            callback()
        }
    }
}
