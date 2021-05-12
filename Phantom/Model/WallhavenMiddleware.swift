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
        let (isIndirectUrl, isDirectUrl) = WallhavenMiddleware.isRightPost(post)
        
        Log.p("wallhaven input url. indirect? \(isIndirectUrl) direct? \(isDirectUrl)")
        
        let (right, alreadyChanged) = (isIndirectUrl, isDirectUrl)
        guard !alreadyChanged else { return (post, changed: true) }
        guard right else { return (post, changed: false) }
        
        let url = URL(string: post.url!)!
        guard let directUrl = try? Wallhaven.getDirectUrl(indirectWallhavenUrl: url) else { return (post, changed: false) }
        
        Log.p("wallhaven direct url found", directUrl)
        
        let newPost = Post.Link(id: post.id,
                                title: post.title,
                                subreddit: post.subreddit,
                                date: post.date,
                                url: directUrl)
        return (newPost, changed: true)
    }
    
    private static func isRightPost(_ post: Post) -> (isIndirectUrl: Bool, isDirectUrl: Bool) {
        guard post.type == .link, let url = post.url else { return (isIndirectUrl: false, isDirectUrl: false) }
        
        if Wallhaven.isIndirectUrl(url) {
            return (isIndirectUrl: true, isDirectUrl: false)
        }
        
        if Wallhaven.isDirectUrl(url) {
            return (isIndirectUrl: false, isDirectUrl: true)
        }
        
        return (isIndirectUrl: false, isDirectUrl: false)
    }
}
