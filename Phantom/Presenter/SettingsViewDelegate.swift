//
//  SettingsViewDelegate.swift
//  Phantom
//
//  Created by River on 2021/06/11.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

protocol SettingsViewDelegate: AnyObject {
    func segueToRedditSignIn()
    func segueToImgurSignIn()
    
    func showBulkAddSubredditAlert(subreddit: String)
    func showInvalidSubredditAlert(tryAgainHandler: (() -> Void)?)
    func showBulkAddTimeAlert(timeOfDay: TimeInterval)
    
    func reloadSettingCell(section: Int, at index: Int) // todo: consistent table view method naming in view delegates (PostTableViewDelegate etc)
}
