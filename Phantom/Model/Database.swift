//
//  Database.swift
//  Phantom
//
//  Created by Rivershy on 2020/08/31.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation

// entirely UserDefaults-backed
class Database {
    private static let KEY_POSTS = "posts"
    private static let KEY_REDDIT_AUTH = "reddit_auth"
    
    static let instance = Database()
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    @UserDefaultsBacked(key: Database.KEY_REDDIT_AUTH) private var redditAuthString: String?
    @UserDefaultsBacked(key: Database.KEY_POSTS) private var postsString: String?
    
    var redditAuth: Reddit.AuthParams? {
        get { deserializeRedditAuth(redditAuthString) }
        set { redditAuthString = serializeRedditAuth(newValue) }
    }
    
    var posts: [Post] = []
    
    private init() {
        // DEBUG VARIABLES
        let wipe = false
        let wipeAuth = false
        let samplePosts = false
        let wipePosts = false
        
        if wipe {
            setDefaults()
        } else {
            if wipeAuth {
                wipeReddit()
            }
            
            if wipePosts {
                posts = []
            } else if samplePosts {
                setSamplePosts()
            } else {
                loadPosts()
            }
            
            savePosts()
        }
    }
    
    func savePosts() {
        postsString = serializePosts(posts)
    }
    
    func setDefaults() {
        redditAuthString = nil
        
        posts = []
        savePosts()
    }
    
    private func loadPosts() {
        if let postsString = postsString {
            posts = deserializePosts(serialized: postsString)
        }
    }
    
    private func setSamplePosts() { // debug
        posts.removeAll()
        40.times { i in
            posts.append(Post(title: "Posty\(i)", text: "texty\(i)", subreddit: "test", date: Date.random))
        }
        
        savePosts()
    }
    
    private func wipeReddit() {
        redditAuthString = nil
    }
    
    private func serializePosts(_ posts: [Post]) -> String {
        let data = try! encoder.encode(posts)
        let serialized = data.base64EncodedString() // String(data: data, encoding: .utf8)!

        return serialized
    }
    
    private func deserializePosts(serialized: String) -> [Post] {
        let data = Data(base64Encoded: serialized)!
        let posts = try! decoder.decode([Post].self, from: data)
        
        return posts
    }
    
    private func serializeRedditAuth(_ auth: Reddit.AuthParams?) -> String? {
        guard let auth = auth else { return nil }
        
        let data = try! encoder.encode(auth)
        let serialized = data.base64EncodedString()
        
        return serialized
    }
    
    private func deserializeRedditAuth(_ serialized: String?) -> Reddit.AuthParams? {
        guard let serialized = serialized else { return nil }
        
        let data = Data(base64Encoded: serialized)!
        let redditAuth = try! decoder.decode(Reddit.AuthParams.self, from: data)
        
        return redditAuth
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
