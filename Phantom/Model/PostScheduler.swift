//
//  PostScheduler.swift
//  Phantom
//
//  Created by River on 2021/05/04.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

// todo: improve gen algorithm for past previous date cases
// todo: add time variance
// todo: add bulk date gen

struct PostScheduler {
    private static let desiredTime = TimeInterval(16 * 60 * 60) // 16:00
    
    private static let day = TimeInterval(24 * 60 * 60) // 24 hours
    
    private static let calendar = Calendar.current
    private static let tz = NSTimeZone.system
    
    static func getNextDate(previous: Date?) -> Date {
        let now = Date()
        
        var nextDate: Date
        if let previous = previous {
            repeat {
                nextDate = addDay(to: previous)
            } while nextDate < now
        } else {
            let dayStart = getDayStart(of: now)
            var desiredDate = makeDesired(dayStart: dayStart)
            
            if now > desiredDate {
                desiredDate = addDay(to: desiredDate)
            }
            
            nextDate = desiredDate
        }
        
        return nextDate
    }
    
    private static func getDayStart(of date: Date) -> Date {
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        dateComponents.timeZone = tz
        
        let dayStart = calendar.date(from: dateComponents)!
        return dayStart
    }
    
    private static func addDay(to date: Date) -> Date {
        return date + day
    }
    
    private static func makeDesired(dayStart: Date) -> Date {
        return dayStart + desiredTime
    }
}
