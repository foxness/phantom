//
//  WallhavenMiddleware.swift
//  Phantom
//
//  Created by River on 2021/04/27.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

struct WallhavenMiddleware: SubmitterMiddleware {
    func transform(post: Post) throws -> (post: Post, changed: Bool) {
        let (right, alreadyChanged) = WallhavenMiddleware.isRightPost(post)
        
        Log.p("wallhaven input url. indirect? \(right) direct? \(alreadyChanged)")
        
        guard !alreadyChanged else { return (post, changed: true) }
        guard right else { return (post, changed: false) }
        
        let url = URL(string: post.url!)!
        guard let directUrl = try? WallhavenMiddleware.getDirectUrl(wallhavenUrl: url) else { return (post, changed: false) }
        
        Log.p("wallhaven direct url found", directUrl)
        
        let newPost = Post.Link(id: post.id,
                                title: post.title,
                                subreddit: post.subreddit,
                                date: post.date,
                                url: directUrl)
        return (newPost, changed: true)
    }
    
    private static func getDirectUrl(wallhavenUrl: URL) throws -> String {
        let request = "wallhaven direct url"
        
        let params = WallhavenMiddleware.getRequestParams(url: wallhavenUrl)
        let (data, response, error) = Requests.synchronousGet(with: params)
        
        let goodData = try Helper.ensureGoodResponse(data: data, response: response, error: error, request: request)
        
        if let html = String(data: goodData, encoding: .utf8),
           let directUrl = getDirectUrl(html: html) {
            
            return directUrl
        } else {
            throw ApiError.deserialization(request: request, raw: String(describing: String(data: goodData, encoding: .utf8)))
        }
    }
    
    private static func getDirectUrl(html: String) -> String? {
        let startKey = "<img id=\"wallpaper\" src=\""
        let endKey = "\""
        
        guard let start = html.range(of: startKey)?.upperBound,
              let end = html.range(of: endKey, options: [], range: start..<html.endIndex , locale: nil)?.lowerBound
        else {
            return nil
        }
        
        let directUrl = html[start..<end]
        return String(directUrl)
    }
    
    private static func isIndirectUrl(_ url: String) -> Bool {
        // indirect: https://wallhaven.cc/w/q22885
        // regex: https://(wallhaven\.cc/w/|whvn\.cc/)\w+
        
        let indirectRegex = "https://(wallhaven\\.cc/w/|whvn\\.cc/)\\w+"
        
        let matches = try! url.matchesRegex(indirectRegex)
        return matches
    }
    
    private static func isDirectUrl(_ url: String) -> Bool {
        // direct: https://w.wallhaven.cc/full/q2/wallhaven-q22885.jpg
        // regex: https://w\.wallhaven\.cc/full/\w+/wallhaven-\w+\.\w+
        
        let directPattern = "https://w\\.wallhaven\\.cc/full/\\w+/wallhaven-\\w+\\.\\w+"
        
        let matches = try! url.matchesRegex(directPattern)
        return matches
    }
    
    private static func isRightPost(_ post: Post) -> (right: Bool, alreadyChanged: Bool) {
        guard post.type == .link, let url = post.url else { return (right: false, alreadyChanged: false) }
        
        if isIndirectUrl(url) {
            return (right: true, alreadyChanged: false)
        }
        
        if isDirectUrl(url) {
            return (right: false, alreadyChanged: true)
        }
        
        return (right: false, alreadyChanged: false)
    }
    
    private static func getRequestParams(url: URL) -> Requests.GetParams {
        return (url: url, auth: nil)
    }
}
