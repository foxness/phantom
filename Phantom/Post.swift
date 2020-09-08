//
//  Post.swift
//  Phantom
//
//  Created by user179800 on 8/30/20.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation

struct Post: Equatable, Codable {
    let title: String
    let text: String
    let subreddit: String
    let date: Date
    
    private enum CodingKeys: String, CodingKey {
        case title, text, subreddit, date // coding keys default to their name, title = "title" etc
    }
    
    func isValid() -> Bool {
        Post.isValid(title: title, text: text, subreddit: subreddit)
    }
    
    static func isValid(title: String, text: String, subreddit: String) -> Bool {
        let goodTitle = !title.isEmpty && title.count < Reddit.LIMIT_TITLE_LENGTH
        let goodText = text.count < Reddit.LIMIT_TEXT_LENGTH
        let goodSubreddit = !subreddit.isEmpty && subreddit.count < Reddit.LIMIT_SUBREDDIT_LENGTH
        
        return goodTitle && goodText && goodSubreddit
    }
    
    static func isValid(post: Post) -> Bool {
        isValid(title: post.title, text: post.text, subreddit: post.subreddit)
    }
}
