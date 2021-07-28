//
//  SettingsDelegate.swift
//  Phantom
//
//  Created by River on 2021/06/15.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

protocol SettingsDelegate: AnyObject {
    func redditAccountChanged(_ newReddit: Reddit?)
    func imgurAccountChanged(_ newImgur: Imgur?)
}
