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
    
    func setSubmissionIndicator(_ state: SubmissionIndicatorState, completion: (() -> Void)?)
    func showAlert(title: String, message: String)
    
    func showSlideUpMenu()
    
    func insertPostRows(at indices: [Int], with animation: ListAnimation)
    func reloadPostRows(with animation: ListAnimation)
    func deletePostRows(at indices: [Int], with animation: ListAnimation)
}
