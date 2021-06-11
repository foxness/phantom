//
//  SettingCell.swift
//  Phantom
//
//  Created by River on 11.06.2021.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import UIKit

class SettingCell: UITableViewCell {
    static let IDENTIFIER = "SettingCell"
    
//    private var label: UILabel!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        textLabel?.text = nil
    }
    
    private func setupViews() {
//        label = UILabel()
//        label.translatesAutoresizingMaskIntoConstraints = false
//
//        addSubview(label)
//
//        label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
//        label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
        
        accessoryType = .disclosureIndicator
    }
    
    public func configure(with option: SettingsOption) {
//        label.text = option.title
        textLabel?.text = option.title
    }
    
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        // Initialization code
//    }
//
//    override func setSelected(_ selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//
//        // Configure the view for the selected state
//    }
}
