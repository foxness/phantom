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

enum SubmissionIndicatorState {
    case hidden, submitting, done
}

protocol PostTableViewDelegate: AnyObject {
    func segueToIntroduction()
    func segueToBulkAdd()
    func segueToSettings()
    
    func showAlert(title: String, message: String)
    func showNotificationPermissionAskAlert(_ callback: @escaping (Bool) -> Void) // (userAgreed: Bool) -> Void
    
    func showSlideUpMenu()
    func setSubmissionIndicator(_ state: SubmissionIndicatorState, completion: (() -> Void)?)
    func showPostSwipeHint()
    
    func insertPostRows(at indices: [Int], with animation: ListAnimation)
    func reloadPostRows(with animation: ListAnimation)
    func deletePostRows(at indices: [Int], with animation: ListAnimation)
}
