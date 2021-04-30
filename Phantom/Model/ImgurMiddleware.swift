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
        if post.type == .link && ImgurMiddleware.isImageUrl(post.url) {
            let url = URL(string: post.url!)!
            guard let imgurImage = uploadToImgur(imageUrl: url) else { return post }

            Log.p("imgur image uploaded", imgurImage)
            
            let title = "\(post.title) [\(imgurImage.width)×\(imgurImage.height)]"

            let newPost = Post.Link(id: post.id,
                                    title: title,
                                    subreddit: post.subreddit,
                                    date: post.date,
                                    url: imgurImage.url)

            return newPost
        }

        return post
    }

    private func uploadToImgur(imageUrl: URL) -> Imgur.Image? {
        imgur.uploadImage(imageUrl: imageUrl)
    }

    private static func isImageUrl(_ url: String?) -> Bool {
        return [".jpg", ".jpeg", ".png"].contains { url?.hasSuffix($0) ?? false }
    }
}
