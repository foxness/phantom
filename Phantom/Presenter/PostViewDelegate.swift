//
//  PostViewDelegate.swift
//  Phantom
//
//  Created by Rivershy on 2020/10/05.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation

protocol PostViewDelegate: AnyObject {
    var postTitle: String { get }
    var postSubreddit: String { get }
    var postDate: Date { get }
    var postType: Post.PostType { get }
    var postUrl: String? { get }
    var postText: String? { get }
    
    func displayPost(_ post: Post)
    
    func indicateNewPost()
    
    func setSaveButton(enabled: Bool)
    
    func dismiss()
}
