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
        ThumbnailResolver.calculateThumbnailUrl(from: url) { [self] calculated in
            setCached(key: url, value: calculated)
            callback(ThumbnailResolver.simplifyThumbnailUrl(calculated))
        }
    }
    
    func removeCached(url: String) {
        cacheQueue.sync(flags: .barrier) {
            unsafeCache.removeValue(forKey: url)
            return // does nothing but remove that warning. still good because shows intention
        }
    }
    
    func isCached(url: String) -> Bool {
        return cacheQueue.sync { unsafeCache.keys.contains(url) }
    }
    
    func getCached(key: String) -> String? {
        let url = cacheQueue.sync { unsafeCache[key] }
        let simplified = ThumbnailResolver.simplifyThumbnailUrl(url)
        return simplified
    }
    
//    private func getCachedComplex(key: String) -> ThumbnailUrl? {
//        return cacheQueue.sync { unsafeCache[key] }
//    }
    
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
        DispatchQueue.global(qos: .userInitiated).async {
            if let imgurUrl = Imgur.calculateThumbnailUrl(from: url) {
                callback(.found(url: imgurUrl))
            } else if let wallhavenUrl = Wallhaven.calculateThumbnailUrl(from: url) {
                callback(.found(url: wallhavenUrl))
            } else if Helper.isImageUrl(url) { // regular/big images count as thumbnails too! :P
                callback(.found(url: url))
            } else {
                calculateGenericThumbnailUrl(from: url, callback: callback)
            }
        }
    }
    
    private static func calculateGenericThumbnailUrl(from url: String, callback: @escaping (ThumbnailUrl) -> Void) {
        let request = "generic thumbnail url"
        
        let params: Requests.GetParams = (url: URL(string: url)!, auth: nil)
        let (data, response, error) = Requests.synchronousGet(with: params)
        
        guard let goodData = try? Helper.ensureGoodResponse(data: data, response: response, error: error, request: request),
              let rawHtml = String(data: goodData, encoding: .utf8),
              let thumbnailUrl = parseThumbnailUrl(rawHtml: rawHtml)
        else {
            Log.p("didn't find thumbnail in generic url", url)
            callback(.calculatedNone)
            return
        }
        
        callback(.found(url: thumbnailUrl))
    }
    
    private static func parseThumbnailUrl(rawHtml: String) -> String? {
        let startKey = " property=\"og:image\" content=\"" // "<meta property=\"og:image\" content=\""
        let endKey = "\""
        
        let thumbnailUrl = rawHtml.findMiddleKey(startKey: startKey, endKey: endKey)
        return thumbnailUrl
    }
}
