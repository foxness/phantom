//
//  SlideUpMenuCell.swift
//  Phantom
//
//  Created by River on 2021/06/15.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import UIKit

class SlideUpMenuCell: BaseCollectionViewCell {
    static let IDENTIFIER = "SlideUpMenuCell"
    
    private var nameLabel: UILabel!
    private var iconView: UIImageView!
    
    override var isHighlighted: Bool {
        didSet {
            nameLabel.textColor = isHighlighted ? .systemBackground : .label
            iconView.tintColor = isHighlighted ? .systemBackground : .secondaryLabel
            
            backgroundColor = isHighlighted ? .secondaryLabel : .systemBackground
        }
    }
    
    override func setupViews() {
        super.setupViews()
        
        nameLabel = UILabel()
        nameLabel.text = "Testy"
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(nameLabel)
        
        iconView = UIImageView()
        iconView.image = UIImage(systemName: "gearshape.fill")
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .secondaryLabel
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(iconView)
        
        addConstraintsWithFormat(format: "H:|-16-[v0(25)]-8-[v1]|", views: iconView, nameLabel)
        addConstraintsWithFormat(format: "V:|[v0]|", views: nameLabel)
        addConstraintsWithFormat(format: "V:[v0(25)]", views: iconView)
        
        iconView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        nameLabel.text = nil
        iconView.image = nil
    }
    
    func configure(for menuItem: SlideUpMenuItem) {
        iconView.image = UIImage(systemName: menuItem.iconSystemName)
        nameLabel.text = menuItem.title
    }
}

class BaseCollectionViewCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        
    }
}
