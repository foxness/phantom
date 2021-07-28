//
//  PostScheduler.swift
//  Phantom
//
//  Created by River on 2021/05/04.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

// todo: add time variance
// todo: add bulk date gen

struct PostScheduler {
    private static let day = TimeInterval(24 * 60 * 60) // 24 hours
    
    let timeOfDay: TimeInterval
    
    func getNextDate(previous: Date?) -> Date {
        let now = Date()
        
        if let previous = previous, PostScheduler.isToday(date: previous) || previous > now {
            return makeDesired(dayStart: PostScheduler.addDay(to: previous.startOfDay))
        }
        
        let desiredDate = makeDesired(dayStart: now.startOfDay)
        return now < desiredDate ? desiredDate : PostScheduler.addDay(to: desiredDate)
    }
    
    private func makeDesired(dayStart: Date) -> Date {
        return dayStart + timeOfDay
    }
    
    private static func addDay(to date: Date) -> Date {
        return date + day
    }
    
    private static func isToday(date: Date) -> Bool {
        return date.startOfDay == Date().startOfDay
    }
}
