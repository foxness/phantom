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
    private enum Key: String {
        case posts
        case thumbnailResolverCache
        case reddit_auth // todo: switch to camelCase
        case imgur_auth
        case introduction_shown
        case wallpaper_mode
        case wallhaven_only
        case direct_image_upload
    }
    
    static let instance = Database()
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    @UserDefaultsBacked(key: Key.reddit_auth.rawValue) private var internalRedditAuth: String?
    @UserDefaultsBacked(key: Key.imgur_auth.rawValue) private var internalImgurAuth: String?
    
    @UserDefaultsBacked(key: Key.introduction_shown.rawValue, defaultValue: false) private var internalIntroductionShown: Bool
    @UserDefaultsBacked(key: Key.wallpaper_mode.rawValue, defaultValue: false) private var internalWallpaperMode: Bool
    @UserDefaultsBacked(key: Key.wallhaven_only.rawValue, defaultValue: false) private var internalWallhavenOnly: Bool
    @UserDefaultsBacked(key: Key.direct_image_upload.rawValue, defaultValue: false) private var internalDirectImageUpload: Bool
    
    @UserDefaultsBacked(key: Key.posts.rawValue) private var internalPosts: String?
    @UserDefaultsBacked(key: Key.thumbnailResolverCache.rawValue) private var internalThumbnailResolverCache: String?
    
    var redditAuth: Reddit.AuthParams? {
        get { deserializeRedditAuth(internalRedditAuth) }
        set { internalRedditAuth = serializeRedditAuth(newValue) }
    }
    
    var imgurAuth: Imgur.AuthParams? {
        get { deserializeImgurAuth(internalImgurAuth) }
        set { internalImgurAuth = serializeImgurAuth(newValue) }
    }
    
    var introductionShown: Bool {
        get { internalIntroductionShown }
        set { internalIntroductionShown = newValue }
    }
    
    var wallpaperMode: Bool {
        get { internalWallhavenOnly }
        set { internalWallhavenOnly = newValue }
    }
    
    var wallhavenOnly: Bool {
        get { internalWallpaperMode }
        set { internalWallpaperMode = newValue }
    }
    
    var directImageUpload: Bool {
        get { internalDirectImageUpload }
        set { internalDirectImageUpload = newValue }
    }
    
    var thumbnailResolverCache: [String: ThumbnailResolver.ThumbnailUrl]? {
        get { deserializeThumbnailResolverCache(internalThumbnailResolverCache) }
        set { internalThumbnailResolverCache = serializeThumbnailResolverCache(newValue) }
    }
    
    var posts: [Post] = []
    
    private init() {
        if DebugVariable.wipeDatabase {
            setDefaults()
        } else {
            if DebugVariable.wipeAuth {
                wipeReddit()
                wipeImgur()
            }
            
            if DebugVariable.wipePosts {
                posts = []
            } else {
                loadPosts()
            }
            
            savePosts()
        }
    }
    
    func savePosts() {
        internalPosts = serializePosts(posts)
    }
    
    func setDefaults() {
        redditAuth = nil
        imgurAuth = nil
        introductionShown = false
        wallpaperMode = false
        wallhavenOnly = false
        directImageUpload = false
        thumbnailResolverCache = nil
        
        posts = []
        savePosts()
    }
    
    private func loadPosts() {
        if let internalPosts = internalPosts {
            posts = deserializePosts(serialized: internalPosts)
        }
    }
    
    private func wipeReddit() {
        redditAuth = nil
    }
    
    private func wipeImgur() {
        imgurAuth = nil
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
    
    private func serializeImgurAuth(_ auth: Imgur.AuthParams?) -> String? {
        guard let auth = auth else { return nil }
        
        let data = try! encoder.encode(auth)
        let serialized = data.base64EncodedString()
        
        return serialized
    }
    
    private func deserializeImgurAuth(_ serialized: String?) -> Imgur.AuthParams? {
        guard let serialized = serialized else { return nil }
        
        let data = Data(base64Encoded: serialized)!
        let imgurAuth = try! decoder.decode(Imgur.AuthParams.self, from: data)
        
        return imgurAuth
    }
    
    private func serializeThumbnailResolverCache(_ auth: [String: ThumbnailResolver.ThumbnailUrl]?) -> String? {
        guard let auth = auth else { return nil }
        
        let data = try! encoder.encode(auth)
        let serialized = data.base64EncodedString()
        
        return serialized
    }
    
    private func deserializeThumbnailResolverCache(_ serialized: String?) -> [String: ThumbnailResolver.ThumbnailUrl]? {
        guard let serialized = serialized else { return nil }
        
        let data = Data(base64Encoded: serialized)!
        let cache = try! decoder.decode([String: ThumbnailResolver.ThumbnailUrl].self, from: data)
        
        return cache
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
