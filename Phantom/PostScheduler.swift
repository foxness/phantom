//
//  PostScheduler.swift
//  Phantom
//
//  Created by user179800 on 9/2/20.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation
import Schedule

struct PostScheduler {
    var task: Task?
    
    mutating func scheduleTask() {
        let work = {
            let notification = Notifications.make(title: "hello there, I'm doing work", body: "asd")
            Notifications.send(notification)
        }
        
        let plan = Plan.after(10.seconds)
        task = plan.do(action: work)
    }
}
