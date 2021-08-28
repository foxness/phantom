//
//  Database.swift
//  Phantom
//
//  Created by Rivershy on 2020/08/31.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation

// todo: improve property order / structure of this class [ez]

// entirely UserDefaults-backed
class Database {
    private enum Key: String {
        case posts = "posts" // string literals left intentionally
        case thumbnailResolverCache = "thumbnailResolverCache"
        case bulkAddSubreddit = "bulkAddSubreddit"
        case bulkAddTime = "bulkAddTime"
        case redditAuth = "redditAuth"
        case imgurAuth = "imgurAuth"
        case introductionShown = "introductionShown"
        case wallpaperMode = "wallpaperMode"
        case useWallhaven = "useWallhaven"
        case useImgur = "useImgur"
        case askedForNotificationPermissions = "askedForNotificationPermissions"
        case sendReplies = "sendReplies"
        case performedOneTimeSetup = "performedOneTimeSetup"
    }
    
    private static let DEFAULT_BULK_ADD_SUBREDDIT = "pics"
    private static let DEFAULT_BULK_ADD_TIME = TimeInterval(12 * 60 * 60) // 12:00
    
    static let instance = Database()
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    @UserDefaultsBacked(key: Key.redditAuth.rawValue) private var internalRedditAuth: String?
    @UserDefaultsBacked(key: Key.imgurAuth.rawValue) private var internalImgurAuth: String?
    
    @UserDefaultsBacked(key: Key.introductionShown.rawValue, defaultValue: false) private var internalIntroductionShown: Bool
    @UserDefaultsBacked(key: Key.askedForNotificationPermissions.rawValue, defaultValue: false) private var internalAskedForNotificationPermissions: Bool
    @UserDefaultsBacked(key: Key.wallpaperMode.rawValue, defaultValue: false) private var internalWallpaperMode: Bool
    @UserDefaultsBacked(key: Key.useWallhaven.rawValue, defaultValue: false) private var internalUseWallhaven: Bool
    @UserDefaultsBacked(key: Key.useImgur.rawValue, defaultValue: false) private var internalUseImgur: Bool
    @UserDefaultsBacked(key: Key.sendReplies.rawValue, defaultValue: true) private var internalSendReplies: Bool
    @UserDefaultsBacked(key: Key.performedOneTimeSetup.rawValue, defaultValue: false) private var internalPerformedOneTimeSetup: Bool // very important for default value to be false here
    
    @UserDefaultsBacked(key: Key.posts.rawValue) private var internalPosts: String?
    @UserDefaultsBacked(key: Key.thumbnailResolverCache.rawValue) private var internalThumbnailResolverCache: String?
    @UserDefaultsBacked(key: Key.bulkAddSubreddit.rawValue, defaultValue: DEFAULT_BULK_ADD_SUBREDDIT) private var internalBulkAddSubreddit: String
    @UserDefaultsBacked(key: Key.bulkAddTime.rawValue, defaultValue: DEFAULT_BULK_ADD_TIME) private var internalBulkAddTime: TimeInterval
    
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
        get { internalWallpaperMode }
        set { internalWallpaperMode = newValue }
    }
    
    var useWallhaven: Bool {
        get { internalUseWallhaven }
        set { internalUseWallhaven = newValue }
    }
    
    var useImgur: Bool {
        get { internalUseImgur }
        set { internalUseImgur = newValue }
    }
    
    var thumbnailResolverCache: [String: ThumbnailResolver.ThumbnailUrl]? {
        get { deserializeThumbnailResolverCache(internalThumbnailResolverCache) }
        set { internalThumbnailResolverCache = serializeThumbnailResolverCache(newValue) }
    }
    
    var bulkAddSubreddit: String {
        get { internalBulkAddSubreddit }
        set { internalBulkAddSubreddit = newValue }
    }
    
    var bulkAddTime: TimeInterval {
        get { internalBulkAddTime }
        set { internalBulkAddTime = newValue }
    }
    
    var askedForNotificationPermissions: Bool {
        get { internalAskedForNotificationPermissions }
        set { internalAskedForNotificationPermissions = newValue }
    }
    
    var sendReplies: Bool {
        get { internalSendReplies }
        set { internalSendReplies = newValue }
    }
    
    var performedOneTimeSetup: Bool {
        get { internalPerformedOneTimeSetup }
        set { internalPerformedOneTimeSetup = newValue }
    }
    
    var posts: [Post] = []
    
    private init() {
        guard performedOneTimeSetup else {
            performOneTimeSetup()
            return
        }
        
        loadPosts()
    }
    
    func savePosts() {
        internalPosts = serializePosts(posts)
    }
    
    func performOneTimeSetup() {
        setDefaults()
        performedOneTimeSetup = true
    }
    
    // defaults are set twice really, once in @UserDefaultsBacked and once here
    func setDefaults() {
        redditAuth = nil
        imgurAuth = nil
        introductionShown = false
        wallpaperMode = false
        useWallhaven = false
        useImgur = false
        thumbnailResolverCache = nil
        bulkAddTime = Database.DEFAULT_BULK_ADD_TIME
        askedForNotificationPermissions = false
        sendReplies = true
        
        resetBulkAddSubreddit()
        
        posts = []
        savePosts()
    }
    
    func resetBulkAddSubreddit() {
        bulkAddSubreddit = Database.DEFAULT_BULK_ADD_SUBREDDIT
    }
    
    private func loadPosts() {
        if let internalPosts = internalPosts {
            posts = deserializePosts(serialized: internalPosts)
        }
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
