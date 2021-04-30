//
//  WallhavenMiddleware.swift
//  Phantom
//
//  Created by River on 2021/04/27.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

struct WallhavenMiddleware: SubmitterMiddleware {
    func transform(post: Post) -> Post {
        if post.type == .link && WallhavenMiddleware.isWallhaven(post.url) {
            let url = URL(string: post.url!)!
            guard let directUrl = WallhavenMiddleware.getDirectUrl(wallhavenUrl: url) else { return post }
            
            Log.p("wallhaven direct url found", directUrl)
            
            let newPost = Post.Link(id: post.id,
                                    title: post.title,
                                    subreddit: post.subreddit,
                                    date: post.date,
                                    url: directUrl)
            
            return newPost
        }
        
        return post
    }
    
    private static func getDirectUrl(wallhavenUrl: URL) -> String? {
        let (data, rawResponse, error) = Requests.synchronousGet(url: wallhavenUrl)
        
        let response = rawResponse as! HTTPURLResponse
        
        if Requests.isResponseOk(response) {
            Log.p("wallhaven middleware: http ok")
        } else {
            Log.p("wallhaven middleware: http not ok, status code: \(response.statusCode), response", response)
        }
        
        if let data = data {
            let html = String(data: data, encoding: .utf8)
            let directUrl = getDirectUrl(html: html!)
            return directUrl
        } else if let error = error {
            Log.p("wallhaven middleware error", error)
        }
        
        return nil
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
    
    private static func isWallhaven(_ url: String?) -> Bool {
        if let url = url {
            return url.contains("wallhaven") // TODO: fix stub with proper regex
        } else {
            return false
        }
    }
}
