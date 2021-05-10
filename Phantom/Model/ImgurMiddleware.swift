//
//  ImgurMiddleware.swift
//  Phantom
//
//  Created by River on 2021/04/28.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

struct ImgurMiddleware: SubmitterMiddleware {
    private let imgur: Imgur
    private let wallpaperMode: Bool
    
    init(_ imgur: Imgur, wallpaperMode: Bool) {
        self.imgur = imgur
        self.wallpaperMode = wallpaperMode
    }
    
    func transform(post: Post) throws -> (post: Post, changed: Bool) {
        guard ImgurMiddleware.isRightPost(post) else { return (post, changed: false) }
        
        let url = URL(string: post.url!)!
        let imgurImage = try! imgur.uploadImage(imageUrl: url)
        Log.p("imgur image uploaded", imgurImage)
        
        let title = wallpaperMode ? "\(post.title) [\(imgurImage.width)×\(imgurImage.height)]" : post.title
        let newPost = Post.Link(id: post.id,
                                title: title,
                                subreddit: post.subreddit,
                                date: post.date,
                                url: imgurImage.url)
        return (newPost, changed: true)
    }
    
    private static func isRightPost(_ post: Post) -> Bool {
        let isImage = [".jpg", ".jpeg", ".png"].contains { post.url?.hasSuffix($0) ?? false }
        return post.type == .link && isImage
    }
}
