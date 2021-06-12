//
//  SignedInAccountSettingCell.swift
//  Phantom
//
//  Created by River on 2021/06/12.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import UIKit

class SignedInAccountSettingCell: UITableViewCell {
    static let IDENTIFIER = "SignedInAccountSettingCell"
    
    @IBOutlet private weak var accountTypeLabel: UILabel!
    @IBOutlet private weak var accountNameLabel: UILabel!
    @IBOutlet private weak var signOutButton: UIButton!
    
    private var signOutHandler: (() -> Void)?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        accountTypeLabel.text = nil
        accountNameLabel.text = nil
        
        signOutHandler = nil
    }
    
    public func configure(with option: AccountSettingsOption) {
        guard option.signedIn else { fatalError("This cell is only for signed in accounts") }
        
        accountTypeLabel.text = option.accountType
        accountNameLabel.text = "/u/\(option.accountName!)"
        
        signOutHandler = option.signOutHandler
    }
    
    @IBAction private func signOutButtonPressed(sender: UIButton) {
        signOutHandler?()
    }
}
