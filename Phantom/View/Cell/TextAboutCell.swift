//
//  TextAboutCell.swift
//  Phantom
//
//  Created by River on 2021/08/19.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import UIKit

class TextAboutCell: UITableViewCell {
    static let IDENTIFIER = "TextAboutCell"
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        titleLabel.text = nil
        valueLabel.text = nil
    }
    
    public func configure(with item: TextAboutItem) {
        titleLabel.text = item.title
        valueLabel.text = item.text
    }
}
