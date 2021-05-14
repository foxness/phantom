//
//  ThumbnailResolver.swift
//  Phantom
//
//  Created by River on 2021/05/14.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

// todo: fix not persistent / save to disk

struct ThumbnailResolver {
    static let instance = ThumbnailResolver()
    
    private let cache = NSCache<NSString, NSString>() // key: url, value: thumbnail url
    
    private init() { }
    
    func resolveThumbnailUrl(with url: String, callback: @escaping (String?) -> Void) {
        let key = url as NSString
        
        if let cached = cache.object(forKey: key) {
            Log.p("found in cache, key: \(key), value: \(cached)")
            callback(cached as String)
        } else {
            Log.p("didn't find in cache, key: \(key)")
            ThumbnailResolver.calculateThumbnailUrl(from: url) { calculated in
                if let calculated = calculated {
                    cache.setObject(calculated as NSString, forKey: key)
                }
                
                callback(calculated)
            }
        }
    }
    
    private static func calculateThumbnailUrl(from url: String, callback: @escaping (String?) -> Void) {
        DispatchQueue.global(qos: .userInteractive).async {
            if let imgurUrl = Imgur.calculateThumbnailUrl(from: url) {
                callback(imgurUrl)
            } else if let wallhavenUrl = Wallhaven.calculateThumbnailUrl(from: url) {
                callback(wallhavenUrl)
            } else {
                callback(nil)
            }
        }
    }
}
