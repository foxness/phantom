//
//  PostTableViewDelegate.swift
//  Phantom
//
//  Created by Rivershy on 2020/10/02.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation

enum ListAnimation {
    case none, top, right, automatic
}

protocol PostTableViewDelegate: AnyObject {
    func segueToIntroduction()
    func segueToRedditLogin()
    
    func setSubmissionIndicator(start: Bool, onDisappear: (() -> Void)?)
    func disableImgurLogin()
    func showSlideUpMenu()
    func updateSlideUpMenu(redditName: String?,  redditLoggedIn: Bool)
    
    func insertPostRows(at indices: [Int], with animation: ListAnimation)
    func reloadPostRows(with animation: ListAnimation)
    func deletePostRows(at indices: [Int], with animation: ListAnimation)
}
