//
//  WallhavenMiddleware.swift
//  Phantom
//
//  Created by River on 2021/04/27.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

// todo: add image dimension extracting from html for mwp?

struct WallhavenMiddleware: SubmitterMiddleware {
    func transform(mwp: MiddlewarePost) throws -> MiddlewareResult {
        let post = mwp.post
        
        let (isIndirectUrl, isDirectUrl) = WallhavenMiddleware.isRightPost(post)
        
        let (right, alreadyChanged) = (isIndirectUrl, isDirectUrl)
        guard !alreadyChanged else { return (mwp, changed: true) }
        guard right else { return (mwp, changed: false) }
        
        let url = URL(string: post.url!)!
        guard let directUrl = try? Wallhaven.getDirectUrl(indirectWallhavenUrl: url) else { return (mwp, changed: false) }
        
        Log.p("wallhaven direct url found", directUrl)
        
        let newPost = Post.Link(id: post.id,
                                title: post.title,
                                subreddit: post.subreddit,
                                date: post.date,
                                url: directUrl)
        
        let newMwp = MiddlewarePost(post: newPost)
        return (newMwp, changed: true)
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
