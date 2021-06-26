//
//  Post.swift
//  Phantom
//
//  Created by Rivershy on 2020/08/30.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation

struct Post: Equatable, Codable {
    enum PostType: String, Codable {
        case text, link
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, title, subreddit, date, type, url, text
    }
    
    let id: UUID
    let title: String
    let subreddit: String
    let date: Date
    
    let type: PostType
    let text: String?
    let url: String?
    
    private init(id: UUID? = nil, title: String, subreddit: String, date: Date, type: PostType, text: String?, url: String?) {
        self.id = id ?? UUID()
        self.title = title
        self.subreddit = subreddit
        self.date = date
        
        self.type = type
        self.text = text
        self.url = url
    }
    
    static func Text(id: UUID? = nil, title: String, subreddit: String, date: Date, text: String) -> Post {
        let type = PostType.text
        let url: String? = nil
        return Post(id: id, title: title, subreddit: subreddit, date: date, type: type, text: text, url: url)
    }
    
    static func Link(id: UUID? = nil, title: String, subreddit: String, date: Date, url: String) -> Post {
        let type = PostType.link
        let text: String? = nil
        return Post(id: id, title: title, subreddit: subreddit, date: date, type: type, text: text, url: url)
    }
    
    func isValid() -> Bool { Post.isValid(self) }
    
    static func isValid(title: String, subreddit: String, type: PostType, text: String?, url: String?) -> Bool {
        return isValidTitle(title) && isValidSubreddit(subreddit) && isValidContent(type: type, text: text, url: url)
    }
    
    static func isValid(_ post: Post) -> Bool {
        isValid(title: post.title,
                subreddit: post.subreddit,
                type: post.type,
                text: post.text,
                url: post.url)
    }
    
    static func isValidTitle(_ title: String) -> Bool {
        return !title.isEmpty && title.count <= Reddit.LIMIT_TITLE_LENGTH
    }
    
    static func isValidSubreddit(_ subreddit: String) -> Bool {
        let regex = NSRegularExpression("^[a-zA-Z0-9_]{1,\(Reddit.LIMIT_SUBREDDIT_LENGTH)}$")
        return regex.matches(subreddit)
    }
    
    static func isValidContent(type: PostType, text: String?, url: String?) -> Bool {
        let goodContent: Bool
        switch type {
        case .text:
            goodContent = text == nil || text!.count <= Reddit.LIMIT_TEXT_LENGTH
        case .link:
            goodContent = url != nil && Helper.isValidUrl(url!)
        }
        
        return goodContent
    }
}
