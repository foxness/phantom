//
//  BulkAddPresenter.swift
//  Phantom
//
//  Created by River on 2021/05/03.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

typealias BarePost = (title: String, url: String)

// todo: add bulk adding text posts?

class BulkAddPresenter {
    private weak var viewDelegate: BulkAddViewDelegate?
    
    private(set) var posts: [BarePost]?
    
    func attachView(_ viewDelegate: BulkAddViewDelegate) {
        self.viewDelegate = viewDelegate
    }
    
    func detachView() {
        viewDelegate = nil
    }
    
    func viewDidLoad() {
        updateAddButton()
    }
    
    private func updateAddButton() {
        let enabled = !(viewDelegate?.bulkText?.trim().isEmpty ?? true)
        viewDelegate?.setAddButton(enabled: enabled)
    }
    
    func addButtonPressed() {
        if let text = viewDelegate?.bulkText,
           let constructedPosts = BulkAddPresenter.constructPosts(text: text) {
            
            posts = constructedPosts
            viewDelegate?.segueBack()
        } else {
            // todo: tell user invalid syntax
            
            Log.p("bad posts")
        }
    }
    
    func pasteButtonPressed() {
        if let clipboard = viewDelegate?.getClipboard() {
            viewDelegate?.bulkText = clipboard
            updateAddButton()
        }
    }
    
    func textChanged() {
        updateAddButton()
    }
    
    private static func constructPosts(text: String) -> [BarePost]? {
        let trimmed = text.trim()
        let rawPosts = trimmed.components(separatedBy: "\n\n")
        
        guard !rawPosts.isEmpty else { return nil }
        
        var constructedPosts = [BarePost]()
        for rawPost in rawPosts {
            let properties = rawPost.components(separatedBy: "\n")
            
            guard properties.count == 2 else { return nil }
            
            let title = properties[0].trim()
            let url = properties[1].trim()
            
            guard Post.isValidTitle(title) && Post.isValidContent(type: .link, text: nil, url: url) else { return nil }
            
            let post = (title: title, url: url)
            constructedPosts.append(post)
        }
        
        return constructedPosts
    }
}
