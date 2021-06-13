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
        var redditAccountName: String? = nil
        var redditSignedIn = false
        
        if let redditAuth = database.redditAuth {
            redditAccountName = "/u/\(redditAuth.username)"
            redditSignedIn = true
        }
        
        let redditSignInHandler = { self.redditSignInPressed() }
        let redditSignOutHandler = { self.redditSignOutPressed() }
        
        let redditOption = AccountSettingsOption(
            accountType: "Reddit account",
            accountName: redditAccountName,
            signedIn: redditSignedIn,
            signInPrompt: "Add Reddit Account",
            signInHandler: redditSignInHandler,
            signOutHandler: redditSignOutHandler
        )
        
        let redditOptionType = SettingsOptionType.accountOption(option: redditOption)
        return redditOptionType
    }
    
    private func getImgurOption() -> SettingsOptionType {
        var imgurAccountName: String? = nil
        var imgurSignedIn = false
        
        if let imgurAuth = database.imgurAuth {
            imgurAccountName = imgurAuth.username
            imgurSignedIn = true
        }
        
        let imgurSignInHandler = { self.imgurSignInPressed() }
        let imgurSignOutHandler = { self.imgurSignOutPressed() }
        
        let imgurOption = AccountSettingsOption(
            accountType: "Imgur account",
            accountName: imgurAccountName,
            signedIn: imgurSignedIn,
            signInPrompt: "Add Imgur Account",
            signInHandler: imgurSignInHandler,
            signOutHandler: imgurSignOutHandler
        )
        
        let imgurOptionType = SettingsOptionType.accountOption(option: imgurOption)
        return imgurOptionType
    }
    
    private func getSettingsSections() -> [SettingsSection] {
        var sections: [SettingsSection] = []
        
        let generalOptions = [getRedditOption(), getImgurOption()]
        let generalSection = SettingsSection(title: "General", options: generalOptions)
        sections.append(generalSection)
        
        return sections
    }
}
