//
//  SwitchSettingCell.swift
//  Phantom
//
//  Created by River on 2021/06/11.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import UIKit

class SwitchSettingCell: UITableViewCell {
    static let IDENTIFIER = "SwitchSettingCell"
    
    @IBOutlet private weak var label: UILabel!
    @IBOutlet private weak var switchControl: UISwitch!
    
    private var handler: ((_ isOn: Bool) -> Void)?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        label.text = nil
        switchControl.isOn = false
        switchControl.isEnabled = true
    }
    
    public func configure(with option: SwitchSettingsOption) {
        label.text = option.title
        
        switchControl.isOn = option.isOn
        switchControl.isEnabled = option.isEnabled
        handler = option.handler
    }
    
    @IBAction private func switchValueChanged(sender: UISwitch) {
        handler?(sender.isOn)
    }
}
