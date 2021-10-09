//
//  SettingsSection.swift
//  Phantom
//
//  Created by River on 2021/06/11.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

struct SettingsSection {
    let title: String
    let footerText: String?
    var options: [SettingsOptionType]
}

enum SettingsOptionType {
    case staticOption(option: StaticSettingsOption)
    case switchOption(option: SwitchSettingsOption)
    case accountOption(option: AccountSettingsOption)
    case textOption(option: TextSettingsOption)
    case timeOption(option: TimeSettingsOption)
}

struct StaticSettingsOption {
    let title: String
    let handler: (() -> Void)?
}

struct SwitchSettingsOption {
    let title: String
    var isOn: Bool
    let handler: ((_ isOn: Bool) -> Void)?
    var isEnabled = true
}

struct AccountSettingsOption {
    let accountType: String
    var accountName: String?
    var signedIn: Bool
    let signInPrompt: String
    let signInHandler: (() -> Void)?
    let signOutHandler: (() -> Void)?
}

struct TextSettingsOption {
    let title: String
    let text: String?
    let handler: (() -> Void)?
}

struct TimeSettingsOption {
    let title: String
    let timeOfDay: TimeInterval
    let handler: ((TimeInterval) -> Void)?
}
