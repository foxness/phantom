//
//  LinkAboutCell.swift
//  Phantom
//
//  Created by River on 2021/08/19.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import UIKit

class LinkAboutCell: UITableViewCell {
    static let IDENTIFIER = "LinkAboutCell"
    
    @IBOutlet weak var label: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        label.text = nil
    }
    
    public func configure(with item: LinkAboutItem) {
        label.text = item.title
    }
}
