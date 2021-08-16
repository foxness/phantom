//
//  SettingsPresenter.swift
//  Phantom
//
//  Created by River on 2021/06/11.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

// todo: make nav bar transparent like in posts table
// todo: make table view fill to the bottom of the screen

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
        case .staticOption, .textOption: return true
        case .accountOption(let accountOption): return !accountOption.signedIn
        case .switchOption, .timeOption: return false
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
        case .textOption(let textOption):
            textOption.handler?()
        default:
            fatalError("This option should not be able to be selected")
        }
    }
    
    // MARK: - Cell update methods // todo: unhardcode this
    
    private func updateRedditAccountCell() {
        viewDelegate?.reloadSettingCell(section: 0, at: 0)
    }
    
    private func updateImgurAccountCell() {
        viewDelegate?.reloadSettingCell(section: 1, at: 0)
    }
    
    private func updateUseImgurCell() {
        viewDelegate?.reloadSettingCell(section: 1, at: 1)
    }
    
    private func updateBulkAddSubredditCell() {
        viewDelegate?.reloadSettingCell(section: 3, at: 0)
    }
    
    private func updateImgurCells() {
        updateImgurAccountCell()
        updateUseImgurCell()
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
    
    func bulkAddSubredditSet(_ subreddit: String?) {
        guard let subreddit = subreddit else { return }
        
        let trimmed = subreddit.trim()
        
        if trimmed.isEmpty {
            database.resetBulkAddSubreddit()
        } else {
            guard Post.isValidSubreddit(trimmed) else {
                viewDelegate?.showInvalidSubredditAlert { [self] in
                    viewDelegate?.showBulkAddSubredditAlert(subreddit: database.bulkAddSubreddit)
                }
                
                return
            }
            
            database.bulkAddSubreddit = trimmed
        }
        
        updateSettings()
        updateBulkAddSubredditCell()
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
        let generalSectionTitle = "" // was "General"
        let imgurSectionTitle = "" // was "Imgur"
        let wallpaperModeSectionTitle = "" // was "Wallpaper Mode"
        let bulkAddSectionTitle = "Bulk Add"
        let aboutSectionTitle = ""
        
        var sections: [SettingsSection] = []
        
        // General section ------------------------------------------------
        
        let generalOptions = [
            getRedditAccountOption(),
            getSendRepliesOption()
        ]
        
        let generalSection = SettingsSection(title: generalSectionTitle, options: generalOptions)
        sections.append(generalSection)
        
        // Imgur section --------------------------------------------------
        
        let imgurOptions = [
            getImgurAccountOption(),
            getUseImgurOption()
        ]
        
        let imgurSection = SettingsSection(title: imgurSectionTitle, options: imgurOptions)
        sections.append(imgurSection)
        
        // Wallpaper Mode section -----------------------------------------
        
        let wallpaperModeOptions = [
            getWallpaperModeOption(),
            getUseWallhavenOption()
        ]
        
        let wallpaperModeSection = SettingsSection(title: wallpaperModeSectionTitle, options: wallpaperModeOptions)
        sections.append(wallpaperModeSection)
        
        // Bulk Add section --------------------------------------------------
        
        let bulkAddOptions = [
            getBulkAddSubredditOption(),
            getBulkAddTimeOption()
        ]
        
        let bulkAddSection = SettingsSection(title: bulkAddSectionTitle, options: bulkAddOptions)
        sections.append(bulkAddSection)
        
        // About section -----------------------------------------------------
        
        let aboutOptions = [
            getAboutOption()
        ]
        
        let aboutSection = SettingsSection(title: aboutSectionTitle, options: aboutOptions)
        sections.append(aboutSection)
        
        // -------------------------------------------------------------------
        
        return sections
    }
    
    // MARK: - General section
    
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
    
    private func getSendRepliesOption() -> SettingsOptionType {
        let title = "Send replies to my inbox"
        
        let sendReplies = database.sendReplies
        
        let handler = { [self] (isOn: Bool) in
            database.sendReplies = isOn
            updateSettings()
        }
        
        let option = SwitchSettingsOption(title: title, isOn: sendReplies, handler: handler)
        let optionType = SettingsOptionType.switchOption(option: option)
        
        return optionType
    }
    
    // MARK: - Imgur section
    
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
    
    private func getUseImgurOption() -> SettingsOptionType {
        let title = "Upload images to Imgur"
        
        let useImgur = database.useImgur
        let isEnabled = database.imgurAuth != nil
        
        let handler = { [self] (isOn: Bool) in
            database.useImgur = isOn
            updateSettings()
        }
        
        let option = SwitchSettingsOption(title: title, isOn: useImgur, handler: handler, isEnabled: isEnabled)
        let optionType = SettingsOptionType.switchOption(option: option)
        
        return optionType
    }
    
    // MARK: - Wallpaper Mode section
    
    private func getWallpaperModeOption() -> SettingsOptionType {
        let title = "Wallpaper Mode"
        
        let wallpaperMode = database.wallpaperMode
        
        let handler = { [self] (isOn: Bool) in
            database.wallpaperMode = isOn
            updateSettings()
        }
        
        let option = SwitchSettingsOption(title: title, isOn: wallpaperMode, handler: handler)
        let optionType = SettingsOptionType.switchOption(option: option)
        
        return optionType
    }
    
    private func getUseWallhavenOption() -> SettingsOptionType {
        let title = "Convert Wallhaven links into image URLs"
        
        let useWallhaven = database.useWallhaven
        
        let handler = { [self] (isOn: Bool) in
            database.useWallhaven = isOn
            updateSettings()
        }
        
        let option = SwitchSettingsOption(title: title, isOn: useWallhaven, handler: handler)
        let optionType = SettingsOptionType.switchOption(option: option)
        
        return optionType
    }
    
    // MARK: - Bulk Add section
    
    private func getBulkAddSubredditOption() -> SettingsOptionType {
        let subreddit = database.bulkAddSubreddit
        
        let title = "Subreddit"
        let text = "/r/\(subreddit)"
        
        let handler = { [self] () -> Void in
            viewDelegate?.showBulkAddSubredditAlert(subreddit: subreddit)
        }
        
        let option = TextSettingsOption(title: title, text: text, handler: handler)
        let optionType = SettingsOptionType.textOption(option: option)
        
        return optionType
    }
    
    private func getBulkAddTimeOption() -> SettingsOptionType {
        let timeOfDay = database.bulkAddTime
        
        let title = "Time of day"
        
        let handler = { [self] (newTime: TimeInterval) -> Void in
            database.bulkAddTime = newTime
            updateSettings()
        }
        
        let option = TimeSettingsOption(title: title, timeOfDay: timeOfDay, handler: handler)
        let optionType = SettingsOptionType.timeOption(option: option)
        
        return optionType
    }
    
    // MARK: - About section
    
    private func getAboutOption() -> SettingsOptionType {
        let title = "About"
        
        let handler = { [self] () -> Void in
            viewDelegate?.segueToAbout()
        }
        
        let option = StaticSettingsOption(title: title, handler: handler)
        let optionType = SettingsOptionType.staticOption(option: option)
        
        return optionType
    }
}
