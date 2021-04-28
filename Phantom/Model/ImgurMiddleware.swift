//
//  ImgurMiddleware.swift
//  Phantom
//
//  Created by River on 2021/04/28.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

//struct ImgurMiddleware: SubmitterMiddleware {
//    static func transform(post: Post) -> Post {
//        if post.type == .link && ImgurMiddleware.isImageUrl(post.url) {
//            let url = URL(string: post.url!)!
//            guard let directUrl = getDirectUrl(wallhavenUrl: url) else { return post }
//
//            Log.p("wallhaven direct url found", directUrl)
//
//            let newPost = Post.Link(id: post.id,
//                                    title: post.title,
//                                    subreddit: post.subreddit,
//                                    date: post.date,
//                                    url: directUrl)
//
//            return newPost
//        }
//
//        return post
//    }
//
//    private static func uploadToImgur
//
//    private static func isImageUrl(_ url: String?) -> Bool {
//        return [".jpg", ".jpeg", ".png"].contains { url?.hasSuffix($0) ?? false }
//    }
//}
