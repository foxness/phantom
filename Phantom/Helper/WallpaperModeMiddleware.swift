//
//  WallpaperModeMiddleware.swift
//  Phantom
//
//  Created by River on 2021/06/19.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

struct WallpaperModeMiddleware: SubmitterMiddleware {
    func transform(mwp: MiddlewarePost) throws -> MiddlewareResult {
        guard let imageWidth = mwp.imageWidth, let imageHeight = mwp.imageHeight else {
            return (mwp, changed: false)
        }
        
        let post = mwp.post
        
        let title = "\(post.title) [\(imageWidth)×\(imageHeight)]"
        let newPost = Post.Link(id: post.id,
                                title: title,
                                subreddit: post.subreddit,
                                date: post.date,
                                url: post.url!)
        
        let newMwp = MiddlewarePost(post: newPost, imageWidth: imageWidth, imageHeight: imageHeight)
        return (newMwp, changed: true)
    }
}
