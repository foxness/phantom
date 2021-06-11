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
    let options: [SettingsOptionType]
}

enum SettingsOptionType {
    case staticOption(option: StaticSettingsOption)
    case switchOption(option: SwitchSettingsOption)
}

struct StaticSettingsOption {
    let title: String
    let handler: (() -> Void)?
}

struct SwitchSettingsOption {
    let title: String
    var isOn: Bool
    let handler: ((_ isOn: Bool) -> Void)?
}
