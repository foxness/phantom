//
//  SettingsPresenter.swift
//  Phantom
//
//  Created by River on 2021/06/11.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

class SettingsPresenter {
    private weak var viewDelegate: SettingsViewDelegate?
    
    private let database: Database = .instance // todo: make them services? implement dip
    
    private var sections: [SettingsSection] = []
    
    func attachView(_ viewDelegate: SettingsViewDelegate) {
        self.viewDelegate = viewDelegate
    }
    
    func detachView() {
        viewDelegate = nil
    }
    
    func viewDidLoad() {
        updateSettings()
    }
    
    func updateSettings() {
        sections = getSettingsSections()
    }
    
    func getOption(section: Int, at index: Int) -> SettingsOptionType {
        return sections[section].options[index]
    }
    
    func getOptionCount(section: Int) -> Int {
        return sections[section].options.count
    }
    
    func getSectionTitle(section: Int) -> String {
        return sections[section].title
    }
    
    func getSectionCount() -> Int {
        return sections.count
    }
    
    func didSelectOption(section: Int, at index: Int) {
        let option = sections[section].options[index]
        switch option {
        case .staticOption(let staticOption):
            staticOption.handler?()
        default: break
        }
    }
    
    func redditSignedIn(_ reddit: Reddit) {
        database.redditAuth = reddit.auth
        updateSettings()
        viewDelegate?.reloadSettingCell(section: 0, at: 0) // unhardcode this
    }
    
    func imgurSignedIn(_ imgur: Imgur) {
        database.imgurAuth = imgur.auth
        updateSettings()
        viewDelegate?.reloadSettingCell(section: 0, at: 1) // unhardcode this
    }
    
    func redditSignOutPressed() {
        database.redditAuth = nil
        updateSettings()
        viewDelegate?.reloadSettingCell(section: 0, at: 0) // unhardcode this
    }
    
    func imgurSignOutPressed() {
        database.imgurAuth = nil
        updateSettings()
        viewDelegate?.reloadSettingCell(section: 0, at: 1) // unhardcode this
    }
    
    func redditSignInPressed() {
        viewDelegate?.segueToRedditSignIn()
    }
    
    func imgurSignInPressed() {
        viewDelegate?.segueToImgurSignIn()
    }
    
    private func getRedditOption() -> SettingsOptionType {
        let accountType = "Reddit Account"
        let signInPrompt = "Add Reddit Account"
        
        var accountName: String? = nil
        var signedIn = false
        
        if let redditAuth = database.redditAuth {
            accountName = "/u/\(redditAuth.username)"
            signedIn = true
        }
        
        let signInHandler = { self.redditSignInPressed() }
        let signOutHandler = { self.redditSignOutPressed() }
        
        let option = AccountSettingsOption(
            accountType: accountType,
            accountName: accountName,
            signedIn: signedIn,
            signInPrompt: signInPrompt,
            signInHandler: signInHandler,
            signOutHandler: signOutHandler
        )
        
        let optionType = SettingsOptionType.accountOption(option: option)
        return optionType
    }
    
    private func getImgurOption() -> SettingsOptionType {
        let accountType = "Imgur Account"
        let signInPrompt = "Add Imgur Account"
        
        var accountName: String? = nil
        var signedIn = false
        
        if let imgurAuth = database.imgurAuth {
            accountName = imgurAuth.username
            signedIn = true
        }
        
        let signInHandler = { self.imgurSignInPressed() }
        let signOutHandler = { self.imgurSignOutPressed() }
        
        let option = AccountSettingsOption(
            accountType: accountType,
            accountName: accountName,
            signedIn: signedIn,
            signInPrompt: signInPrompt,
            signInHandler: signInHandler,
            signOutHandler: signOutHandler
        )
        
        let optionType = SettingsOptionType.accountOption(option: option)
        return optionType
    }
    
    private func getWallpaperModeOption() -> SettingsOptionType {
        let title = "Wallpaper Mode"
        
        let wallpaperMode = database.wallpaperMode
        
        let handler = { (isOn: Bool) in
            self.database.wallpaperMode = isOn
            self.updateSettings()
        }
        
        let option = SwitchSettingsOption(title: title, isOn: wallpaperMode, handler: handler)
        let optionType = SettingsOptionType.switchOption(option: option)
        
        return optionType
    }
    
    private func getSettingsSections() -> [SettingsSection] {
        var sections: [SettingsSection] = []
        
        let generalOptions = [
            getRedditOption(),
            getImgurOption(),
            getWallpaperModeOption()
        ]
        
        let generalSection = SettingsSection(title: "General", options: generalOptions)
        sections.append(generalSection)
        
        return sections
    }
}
