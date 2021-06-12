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
    
    private var sections: [SettingsSection]
    
    init() {
        sections = SettingsPresenter.getSettingsSections()
    }
    
    func attachView(_ viewDelegate: SettingsViewDelegate) {
        self.viewDelegate = viewDelegate
    }
    
    func detachView() {
        viewDelegate = nil
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
    
    private static func getSettingsSections() -> [SettingsSection] {
        var sections: [SettingsSection] = []
        
        let redditOption = AccountSettingsOption(accountType: "Reddit account", accountName: "testy", signedIn: true, signInHandler: { Log.p("reddit sign in pressed") }, signOutHandler: { Log.p("reddit sign out pressed") })
        let redditOptionType = SettingsOptionType.accountOption(option: redditOption)
        let generalOptions = [redditOptionType]
        let generalSection = SettingsSection(title: "General", options: generalOptions)
        
        sections.append(generalSection)
        
//        Array(1...3).map {
//            let options: [SettingsOptionType] = Array(1...5).map {
//                let n = $0
//                switch n % 2 {
//                case 0: return .staticOption(option: StaticSettingsOption(title: "Static Option \($0)") { Log.p("Static Option \(n) pressed") })
//                case 1: return .switchOption(option: SwitchSettingsOption(title: "Switch Option \($0)", isOn: n % 2 == 1) { Log.p("Switch Option \(n) switched to \($0)") })
//                default: fatalError()
//                }
//            }
//
//            return SettingsSection(title: "Section \($0)", options: options)
//        }.forEach {
//            sections.append($0)
//        }
        
//        options.append(SettingsOption(title: "Option", handler: {
//
//        }))
        
        return sections
    }
}
