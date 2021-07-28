//
//  SignedOutAccountSettingCell.swift
//  Phantom
//
//  Created by River on 2021/06/12.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import UIKit

// todo: remove this cell and use StaticSettingCell instead?

class SignedOutAccountSettingCell: UITableViewCell {
    static let IDENTIFIER = "SignedOutAccountSettingCell"
    
    @IBOutlet private weak var signInButton: UIButton!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        signInButton.setTitle(nil, for: .normal)
    }
    
    public func configure(with option: AccountSettingsOption) {
        guard !option.signedIn else { fatalError("This cell is only for signed out accounts") }
        
        signInButton.setTitle(option.signInPrompt, for: .normal)
    }
}

