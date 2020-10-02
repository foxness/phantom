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
    
    func insertRows(at indices: [Int], with animation: ListAnimation)
    func reloadSection(with animation: ListAnimation)
    func deleteRows(at indices: [Int], with animation: ListAnimation)
    
    func setSubmissionIndicator(start: Bool, onDisappear: (() -> Void)?)
}
