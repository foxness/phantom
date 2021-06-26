//
//  TextSettingCell.swift
//  Phantom
//
//  Created by River on 2021/06/26.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import UIKit

class TextSettingCell: UITableViewCell {
    static let IDENTIFIER = "TextSettingCell"
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        titleLabel.text = nil
        valueLabel.text = nil
    }
    
    public func configure(with option: TextSettingsOption) {
        titleLabel.text = option.title
        valueLabel.text = option.text
    }
}
