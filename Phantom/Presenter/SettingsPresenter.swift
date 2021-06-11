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
    
    func getOption(section: Int, at index: Int) -> SettingsOption {
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
    
    private static func getSettingsSections() -> [SettingsSection] {
        var sections: [SettingsSection] = []
        
        
        
        Array(1...3).map {
            let options: [SettingsOption] = Array(1...5).map { SettingsOption(title: "Option \($0)", handler: nil) }
            return SettingsSection(title: "Section \($0)", options: options)
        }.forEach {
            sections.append($0)
        }
        
        
        
//        options.append(SettingsOption(title: "Option", handler: {
//
//        }))
        
        return sections
    }
}
