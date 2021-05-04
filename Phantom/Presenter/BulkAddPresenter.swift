//
//  BulkAddPresenter.swift
//  Phantom
//
//  Created by River on 2021/05/03.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

typealias BarePost = (title: String, url: String)

class BulkAddPresenter { // todo: add paste button
    private weak var viewDelegate: BulkAddViewDelegate?
    
    var posts: [BarePost]?
    
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
        let enabled = !(viewDelegate?.postsText?.isEmpty ?? true)
        viewDelegate?.setAddButton(enabled: enabled)
    }
    
    func addButtonPressed() {
        let raw = viewDelegate!.postsText!
        posts = BulkAddPresenter.constructPosts(text: raw)
    }
    
    func cancelButtonPressed() {
        viewDelegate?.dismiss()
    }
    
    func pasteButtonPressed() {
        if let clipboard = viewDelegate?.getClipboard() {
            viewDelegate?.postsText = clipboard
        }
    }
    
    func textChanged() {
        updateAddButton()
    }
    
    private static func constructPosts(text: String) -> [BarePost]? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let rawPosts = trimmed.components(separatedBy: "\n\n")
        
        var constructedPosts = [BarePost]()
        for rawPost in rawPosts {
            let properties = rawPost.components(separatedBy: "\n")
            
            // todo: return nil is count isnt 2
            
            let title = properties[0]
            let url = properties[1]
            
            guard !title.isEmpty && URL(string: url) != nil else { return nil }
            
            let post = (title: title, url: url)
            constructedPosts.append(post)
        }
        
        return constructedPosts
    }
}
