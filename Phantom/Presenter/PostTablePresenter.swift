//
//  PostTablePresenter.swift
//  Phantom
//
//  Created by Rivershy on 10/2/20.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation

class PostTablePresenter {
    private weak var viewDelegate: PostTableViewDelegate?
    
    func attachView(_ viewDelegate: PostTableViewDelegate) {
        self.viewDelegate = viewDelegate
    }
    
    func detachView() {
        viewDelegate = nil
    }
}
