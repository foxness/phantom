//
//  PostPresenter.swift
//  Phantom
//
//  Created by Rivershy on 2020/10/05.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation

class PostPresenter {
    private weak var viewDelegate: PostViewDelegate?
    
    private let database: Database = .instance
    
    private var post: Post?
    private(set) var isNewPost = false
    
    var resultingPost: Post { post! }
    
    func attachView(_ viewDelegate: PostViewDelegate) {
        self.viewDelegate = viewDelegate
    }
    
    func detachView() {
        viewDelegate = nil
    }
    
    func postSupplied(_ post: Post) {
        self.post = post
    }
    
    func viewDidLoad() {
        if post == nil {
            isNewPost = true
            post = getDefaultNewPost()
            viewDelegate?.indicateNewPost()
        }
        
        viewDelegate?.displayPost(post!)
        updateSaveButton()
    }
    
    private func updateSaveButton() {
        let post = constructPost()
        let isPostValid = post.isValid()
        viewDelegate?.setSaveButton(enabled: isPostValid)
    }
    
    func constructPost() -> Post {
        guard let post = post, let viewDelegate = viewDelegate else { fatalError() }
        
        let id = post.id
        let title = viewDelegate.postTitle
        let subreddit = viewDelegate.postSubreddit
        let date = viewDelegate.postDate
        
        let postType = viewDelegate.postType
        let constructedPost: Post
        
        switch postType {
        case .link:
            let url = viewDelegate.postUrl!
            constructedPost = Post.Link(id: id, title: title, subreddit: subreddit, date: date, url: url)
        case .text:
            let text = viewDelegate.postText!
            constructedPost = Post.Text(id: id, title: title, subreddit: subreddit, date: date, text: text)
        }
        
        return constructedPost
    }
    
    func saveButtonPressed() {
        post = constructPost()
    }
    
    func cancelButtonPressed() {
        viewDelegate?.dismiss()
    }
    
    func postTypeChanged() {
        updateSaveButton()
    }
    
    func titleChanged() {
        updateSaveButton()
    }
    
    func subredditChanged() {
        updateSaveButton()
    }
    
    func textChanged() {
        updateSaveButton()
    }
    
    private func getDefaultNewPost() -> Post {
        let title = ""
        let url = ""
        
        let subreddit = database.newPostDefaultSubreddit ?? ""
        
        // TODO: set a realistic new post date
        let date = Date() + 60 * 60 // 1 hour from now
        
        return Post.Link(title: title, subreddit: subreddit, date: date, url: url)
    }
}
