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
        guard WallhavenMiddleware.isRightPost(post) else { return (post, changed: false) }
        
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
        
        let (data, response, error) = Requests.synchronousGet(url: wallhavenUrl)
        
        try Helper.ensureGoodResponse(response: response, request: request)
        try Helper.ensureNoError(error: error, request: request)
        
        guard let data = data else {
            throw ApiError.noData(request: request)
        }
        
        if let html = String(data: data, encoding: .utf8),
           let directUrl = getDirectUrl(html: html) {
            
            return directUrl
        } else {
            throw ApiError.deserialization(request: request, json: nil)
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
    
    private static func isRightPost(_ post: Post) -> Bool {
        let wallhaven = post.url?.contains("wallhaven") ?? false // TODO: fix stub with proper regex
        return post.type == .link && wallhaven
    }
}
