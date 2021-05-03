//
//  BulkAddPresenter.swift
//  Phantom
//
//  Created by River on 2021/05/03.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

class BulkAddPresenter {
    private weak var viewDelegate: BulkAddViewDelegate?
    
    var posts: [Post]?
    
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
    
    func textChanged() {
        updateAddButton()
    }
    
    private static func constructPosts(text: String) -> [Post]? {
        return nil
    }
}
