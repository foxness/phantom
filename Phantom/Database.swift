//
//  Database.swift
//  Phantom
//
//  Created by user179800 on 8/31/20.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation

struct Database {
    private static let KEY_POST_TITLE = "post_title"
    private static let KEY_POST_TEXT = "post_text"
    private static let KEY_POST_SUBREDDIT = "post_subreddit"
    
    private static let DEFAULT_POST_TITLE = "testy is besty"
    private static let DEFAULT_POST_TEXT = "contenty mccontentface"
    private static let DEFAULT_POST_SUBREDDIT = "test"
    
    static let instance = Database()
    
    @UserDefaultsBacked(key: Database.KEY_POST_TITLE, defaultValue: Database.DEFAULT_POST_TITLE) var postTitle: String
    @UserDefaultsBacked(key: Database.KEY_POST_TEXT, defaultValue: Database.DEFAULT_POST_TEXT) var postText: String
    @UserDefaultsBacked(key: Database.KEY_POST_SUBREDDIT, defaultValue: Database.DEFAULT_POST_SUBREDDIT) var postSubreddit: String
    
    private init() {
        // setDefaults()
    }
    
    mutating func setDefaults() {
        postTitle = Database.DEFAULT_POST_TITLE
        postText = Database.DEFAULT_POST_TEXT
        postSubreddit = Database.DEFAULT_POST_SUBREDDIT
    }
}

// SOURCE: https://www.swiftbysundell.com/articles/property-wrappers-in-swift/

private protocol AnyOptional {
    var isNil: Bool { get }
}

extension Optional: AnyOptional {
    var isNil: Bool { self == nil }
}

@propertyWrapper
struct UserDefaultsBacked<Value> {
    let key: String
    let defaultValue: Value
    let storage: UserDefaults = .standard
    
    var wrappedValue: Value {
        get {
            (storage.value(forKey: key) as? Value) ?? defaultValue
        }
        
        set {
            if let optional = newValue as? AnyOptional, optional.isNil {
                storage.removeObject(forKey: key)
            } else {
                storage.set(newValue, forKey: key)
            }
        }
    }
}

extension UserDefaultsBacked where Value: ExpressibleByNilLiteral {
    init(key: String) {
        self.init(key: key, defaultValue: nil)
    }
}
