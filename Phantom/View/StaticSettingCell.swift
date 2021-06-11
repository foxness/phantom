//
//  StaticSettingCell.swift
//  Phantom
//
//  Created by River on 2021/06/11.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import UIKit

class StaticSettingCell: UITableViewCell {
    static let IDENTIFIER = "StaticSettingCell"
    
    @IBOutlet weak var label: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        label.text = nil
    }
    
    public func configure(with option: StaticSettingsOption) {
        label.text = option.title
    }
}
