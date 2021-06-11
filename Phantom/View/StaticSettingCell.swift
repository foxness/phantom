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
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        textLabel?.text = nil
    }
    
    private func setupViews() {
        accessoryType = .disclosureIndicator
    }
    
    public func configure(with option: StaticSettingsOption) {
        textLabel?.text = option.title
    }
}
