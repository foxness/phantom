//
//  SlideUpMenuDelegate.swift
//  Phantom
//
//  Created by River on 2021/05/10.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

protocol SlideUpMenuDelegate: AnyObject {
    func redditButtonPressed()
    func imgurButtonPressed()
    func bulkAddButtonPressed()
    
    func wallpaperModeSwitched(on: Bool)
    func wallhavenOnlySwitched(on: Bool)
    func directImageUploadSwitched(on: Bool)
}
