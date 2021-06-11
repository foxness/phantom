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
    
    private var options: [SettingsOption]
    
    init() {
        options = SettingsPresenter.getSettingsOptions()
    }
    
    func attachView(_ viewDelegate: SettingsViewDelegate) {
        self.viewDelegate = viewDelegate
    }
    
    func detachView() {
        viewDelegate = nil
    }
    
    func getOption(at index: Int) -> SettingsOption {
        return options[index]
    }
    
    func getOptionCount() -> Int {
        return options.count
    }
    
    private static func getSettingsOptions() -> [SettingsOption] {
        var options: [SettingsOption] = []
        
        Array(1...100).map { SettingsOption(title: "Option \($0)", handler: nil) }.forEach {
            options.append($0)
        }
        
//        options.append(SettingsOption(title: "Option", handler: {
//
//        }))
        
        return options
    }
}
