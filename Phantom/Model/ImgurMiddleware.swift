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
    
    init(_ imgur: Imgur) {
        self.imgur = imgur
    }
    
    func transform(post: Post) -> Post {
        guard ImgurMiddleware.isRightPost(post) else { return post }
        
        let url = URL(string: post.url!)!
        let imgurImage = try! imgur.uploadImage(imageUrl: url)
        Log.p("imgur image uploaded", imgurImage)
        
        let title = "\(post.title) [\(imgurImage.width)×\(imgurImage.height)]"
        let newPost = Post.Link(id: post.id,
                                title: title,
                                subreddit: post.subreddit,
                                date: post.date,
                                url: imgurImage.url)
        return newPost
    }
    
    private static func isRightPost(_ post: Post) -> Bool {
        let isImage = [".jpg", ".jpeg", ".png"].contains { post.url?.hasSuffix($0) ?? false }
        return post.type == .link && isImage
    }
}
