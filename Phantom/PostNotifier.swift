//
//  PostNotifier.swift
//  Phantom
//
//  Created by user179838 on 9/11/20.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation

struct PostNotifier {
    private init() { }
    
    static func notify(for post: Post) {
        let date = post.date
        guard date > Date() else { return }
        
        let title = post.title
        let body = "Time to submit has come"
        
        let id = post.id.uuidString
        let dc = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        
        Notifications.request(id: id, title: title, body: body, dateComponents: dc) { error in
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
}
