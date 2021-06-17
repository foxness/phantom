//
//  SettingsPresenter.swift
//  Phantom
//
//  Created by River on 2021/06/11.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

class SettingsPresenter {
    // MARK: - Properties
    
    private weak var viewDelegate: SettingsViewDelegate?
    weak var delegate: SettingsDelegate?
    
    private let database: Database = .instance // todo: make them services? implement dip
    
    private var sections: [SettingsSection] = []
    
    // MARK: - View delegate
    
    func attachView(_ viewDelegate: SettingsViewDelegate) {
        self.viewDelegate = viewDelegate
    }
    
    func detachView() {
        viewDelegate = nil
    }
    
    // MARK: - Public methods
    
    func viewDidLoad() {
        updateSettings()
    }
    
    private func updateSettings() {
        sections = getSettingsSections()
    }
    
    // MARK: - Settings option data source
    
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
    
    func isSelectableOption(section: Int, at index: Int) -> Bool { // selectable means triggering didSelectOption
        let option = sections[section].options[index]
        switch option {
        case .staticOption: return true
        case .accountOption(let accountOption): return !accountOption.signedIn
        default: return false
        }
    }
    
    func didSelectOption(section: Int, at index: Int) {
        let option = sections[section].options[index]
        switch option {
        case .staticOption(let staticOption):
            staticOption.handler?()
        case .accountOption(let accountOption):
            guard !accountOption.signedIn else { break }
            accountOption.signInHandler?()
        default:
            fatalError("This option should not be able to be selected")
        }
    }
    
    // MARK: - Cell update methods
    
    func updateRedditAccountCell() {
        viewDelegate?.reloadSettingCell(section: 0, at: 0) // unhardcode this
    }
    
    func updateImgurCells() {
        viewDelegate?.reloadSettingCell(section: 1, at: 0) // unhardcode this
        viewDelegate?.reloadSettingCell(section: 1, at: 1)
    }
    
    // MARK: - Receiver methods
    
    func redditSignedIn(_ reddit: Reddit) {
        database.redditAuth = reddit.auth
        updateSettings()
        updateRedditAccountCell()
        
        delegate?.redditAccountChanged(reddit)
    }
    
    func imgurSignedIn(_ imgur: Imgur) {
        database.imgurAuth = imgur.auth
        database.useImgur = true
        
        updateSettings()
        updateImgurCells()
        
        delegate?.imgurAccountChanged(imgur)
    }
    
    // MARK: - User interaction methods
    
    private func redditSignOutPressed() {
        database.redditAuth = nil
        
        updateSettings()
        updateRedditAccountCell()
        
        delegate?.redditAccountChanged(nil)
    }
    
    private func imgurSignOutPressed() {
        database.imgurAuth = nil
        database.useImgur = false
        
        updateSettings()
        updateImgurCells()
        
        delegate?.imgurAccountChanged(nil)
    }
    
    private func redditSignInPressed() {
        viewDelegate?.segueToRedditSignIn()
    }
    
    private func imgurSignInPressed() {
        viewDelegate?.segueToImgurSignIn()
    }
    
    // MARK: - Settings sections
    
    private func getSettingsSections() -> [SettingsSection] {
        let generalSectionTitle = "General"
        let imgurSectionTitle = "Imgur"
        
        var sections: [SettingsSection] = []
        
        let generalOptions = [
            getRedditAccountOption(),
            getWallpaperModeOption(),
            getUseWallhavenOption()
        ]
        
        let generalSection = SettingsSection(title: generalSectionTitle, options: generalOptions)
        sections.append(generalSection)
        
        let imgurOptions = [
            getImgurAccountOption(),
            getUseImgurOption()
        ]
        
        let imgurSection = SettingsSection(title: imgurSectionTitle, options: imgurOptions)
        sections.append(imgurSection)
        
        return sections
    }
    
    private func getRedditAccountOption() -> SettingsOptionType {
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
    
    private func getImgurAccountOption() -> SettingsOptionType {
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
    
    private func getUseWallhavenOption() -> SettingsOptionType {
        let title = "Use Wallhaven"
        
        let useWallhaven = database.useWallhaven
        
        let handler = { (isOn: Bool) in
            self.database.useWallhaven = isOn
            self.updateSettings()
        }
        
        let option = SwitchSettingsOption(title: title, isOn: useWallhaven, handler: handler)
        let optionType = SettingsOptionType.switchOption(option: option)
        
        return optionType
    }
    
    private func getUseImgurOption() -> SettingsOptionType {
        let title = "Upload images to Imgur"
        
        let useImgur = database.useImgur
        let isEnabled = database.imgurAuth != nil
        
        let handler = { (isOn: Bool) in
            self.database.useImgur = isOn
            self.updateSettings()
        }
        
        let option = SwitchSettingsOption(title: title, isOn: useImgur, handler: handler, isEnabled: isEnabled)
        let optionType = SettingsOptionType.switchOption(option: option)
        
        return optionType
    }
}
