//
//  Database.swift
//  Phantom
//
//  Created by user179800 on 8/31/20.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation

// todo: make database a class because its being passed around and is a singleton
// todo^^^: should singletons be structs or classes??!?!?

struct Database {
    private static let KEY_POSTS = "posts"
    private static let KEY_REDDIT_REFRESH_TOKEN = "reddit_refresh_token"
    private static let KEY_REDDIT_ACCESS_TOKEN = "reddit_access_token"
    private static let KEY_REDDIT_ACCESS_TOKEN_EXPIRATION_DATE = "reddit_access_token_expiration_date"
    
    static let instance = Database()
    
    @UserDefaultsBacked(key: Database.KEY_REDDIT_REFRESH_TOKEN) var redditRefreshToken: String?
    @UserDefaultsBacked(key: Database.KEY_REDDIT_ACCESS_TOKEN) var redditAccessToken: String?
    
    @UserDefaultsBacked(key: Database.KEY_REDDIT_ACCESS_TOKEN_EXPIRATION_DATE) private var redditAccessTokenExpirationDateString: String?
    @UserDefaultsBacked(key: Database.KEY_POSTS) private var postsString: String?
    
    var redditAccessTokenExpirationDate: Date? {
        get { Database.deserializeDate(redditAccessTokenExpirationDateString) }
        set { redditAccessTokenExpirationDateString = Database.serializeDate(newValue) }
    }
    
    var posts: [Post] = []
    
    private init() {
        let wipe = true // debug
        
        if wipe {
            setDefaults()
        } else {
            if let postsString = postsString {
                posts = Database.deserializePosts(serialized: postsString)
            }
        }
    }
    
    mutating func savePosts() {
        postsString = Database.serializePosts(posts)
    }
    
    mutating func setDefaults() {
        let wipeReddit = false // debug
        
        if wipeReddit {
            redditRefreshToken = nil
            redditAccessToken = nil
            redditAccessTokenExpirationDateString = nil
        }
        
        posts.removeAll()
        20.times { i in
            posts.append(Post(title: "Posty\(i)", text: "texty\(i)", subreddit: "test", date: Date.random))
        }
        
        savePosts()
    }
    
    private static func serializePosts(_ posts: [Post]) -> String {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(posts)
        let serialized = data.base64EncodedString() // String(data: data, encoding: .utf8)!

        return serialized
    }
    
    private static func deserializePosts(serialized: String) -> [Post] {
        let decoder = JSONDecoder()
        let data = Data(base64Encoded: serialized)!
        let posts = try! decoder.decode([Post].self, from: data)
        
        return posts
    }
    
    private static func serializeDate(_ date: Date?) -> String? {
        date == nil ? nil : String(date!.timeIntervalSinceReferenceDate)
    }
    
    private static func deserializeDate(_ string: String?) -> Date? {
        string == nil ? nil : Date(timeIntervalSinceReferenceDate: TimeInterval(string!)!)
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
