//
//  ThumbnailResolver.swift
//  Phantom
//
//  Created by River on 2021/05/14.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

// todo: add auto cache cleaning

class ThumbnailResolver {
    enum ThumbnailUrl: Codable {
        case calculatedNone
        case found(url: String)
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: Key.self)
            let found = try container.decode(Int.self, forKey: .found)
            switch found {
            case 0:
                self = .calculatedNone
            case 1:
                let url = try container.decode(String.self, forKey: .url)
                self = .found(url: url)
            default:
                throw CodingError.unknownValue
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: Key.self)
            switch self {
            case .calculatedNone:
                try container.encode(0, forKey: .found)
            case .found(let url):
                try container.encode(1, forKey: .found)
                try container.encode(url, forKey: .url)
            }
        }
        
        enum Key: CodingKey {
            case found
            case url
        }
        
        enum CodingError: Error {
            case unknownValue
        }
    }
    
    static let instance = ThumbnailResolver()
    
    private let cacheQueue = DispatchQueue(label: "com.rivershy.Phantom.ThumbnailResolver.cacheQueue", attributes: .concurrent)
    private var unsafeCache = [String: ThumbnailUrl]() // key: url, value: thumbnail url
    
    var cache: [String: ThumbnailUrl] {
        get { cacheQueue.sync { unsafeCache } }
        set { cacheQueue.sync(flags: .barrier) { unsafeCache = newValue } }
    }
    
    private init() { }
    
    func resolveThumbnailUrl(with url: String, callback: @escaping (String?) -> Void) {
        let key = url
        
        if let cached = getCached(key: key) {
            Log.p("found in cache, key: \(key), value: \(cached)")
            callback(ThumbnailResolver.simplifyThumbnailUrl(cached))
        } else {
            Log.p("didn't find in cache, key: \(key)")
            ThumbnailResolver.calculateThumbnailUrl(from: url) { [self] calculated in
                setCached(key: key, value: calculated)
                callback(ThumbnailResolver.simplifyThumbnailUrl(calculated))
            }
        }
    }
    
    func removeCached(url: String) {
        cacheQueue.sync(flags: .barrier) {
            unsafeCache.removeValue(forKey: url)
            return // does nothing but remove that warning. still good because shows intention
        }
    }
    
    private func getCached(key: String) -> ThumbnailUrl? {
        return cacheQueue.sync { unsafeCache[key] }
    }
    
    private func setCached(key: String, value: ThumbnailUrl) {
        cacheQueue.sync(flags: .barrier) {
            unsafeCache[key] = value
        }
    }
    
    private static func simplifyThumbnailUrl(_ thumbnailUrl: ThumbnailUrl?) -> String? {
        if let thumbnailUrl = thumbnailUrl {
            switch thumbnailUrl {
            case .found(let url): return url
            default: break
            }
        }
        
        return nil
    }
    
    private static func calculateThumbnailUrl(from url: String, callback: @escaping (ThumbnailUrl) -> Void) {
        DispatchQueue.global(qos: .userInteractive).async {
            if let imgurUrl = Imgur.calculateThumbnailUrl(from: url) {
                callback(.found(url: imgurUrl))
            } else if let wallhavenUrl = Wallhaven.calculateThumbnailUrl(from: url) {
                callback(.found(url: wallhavenUrl))
            } else {
                callback(.calculatedNone)
            }
        }
    }
}
