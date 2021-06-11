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
    
    private var switchControl: UISwitch!
    private var handler: ((_ isOn: Bool) -> Void)?
    
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
        switchControl.isOn = false
    }
    
    private func setupViews() {
        switchControl = UISwitch()
        switchControl.onTintColor = .systemBlue
        switchControl.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
        switchControl.translatesAutoresizingMaskIntoConstraints = false

        // should be contentView.addSubview() and not addSubview()
        // because it puts the switch control on top so that it is tappable
        contentView.addSubview(switchControl)
        
        let constraints = [
            switchControl.centerYAnchor.constraint(equalTo: centerYAnchor),
            switchControl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    public func configure(with option: SwitchSettingsOption) {
        textLabel?.text = option.title
        
        switchControl.isOn = option.isOn
        handler = option.handler
    }
    
    @objc private func switchValueChanged(sender: UISwitch) {
        handler?(sender.isOn)
    }
}
