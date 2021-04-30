//
//  Helper.swift
//  Phantom
//
//  Created by River on 2021/04/30.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

struct Helper {
    private static let RANDOM_STATE_LENGTH = 10
    
    static func getQueryItems(url: URL) -> [String: String] {
        let urlc = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let params = urlc.queryItems!.reduce(into: [String:String]()) { $0[$1.name] = $1.value }
        
        return params
    }
    
    static func convertExpiresIn(_ expiresIn: Int) -> Date {
        return Date(timeIntervalSinceNow: TimeInterval(expiresIn))
    }
    
    static func getRandomState(length: Int = RANDOM_STATE_LENGTH) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }
    
    static func toUrlQueryItems(query: [String: String]) -> [URLQueryItem] {
        return query.map { URLQueryItem(name: $0.key, value: $0.value) }
    }
    
    static func appendQuery(url: String, query: [String: String]) -> URL {
        var urlc = URLComponents(string: url)!
        urlc.queryItems = Helper.toUrlQueryItems(query: query)
        return urlc.url!
    }
}
