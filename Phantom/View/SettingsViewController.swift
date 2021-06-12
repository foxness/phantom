//
//  SettingsViewController.swift
//  Phantom
//
//  Created by River on 2021/06/11.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private var presenter = SettingsPresenter()
    
    @IBOutlet private var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
    }
    
    func setupViews() {
//        tableView.rowHeight = UITableView.automaticDimension
//        tableView.estimatedRowHeight = 50
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return presenter.getSectionCount()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presenter.getOptionCount(section: section)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return presenter.getSectionTitle(section: section)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        presenter.didSelectOption(section: indexPath.section, at: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let option = presenter.getOption(section: indexPath.section, at: indexPath.row)
        switch option {
        case .staticOption(let option):
            let staticCell = tableView.dequeueReusableCell(withIdentifier: StaticSettingCell.IDENTIFIER, for: indexPath) as! StaticSettingCell
            
            staticCell.configure(with: option)
            return staticCell
            
        case .switchOption(let option):
            let switchCell = tableView.dequeueReusableCell(withIdentifier: SwitchSettingCell.IDENTIFIER, for: indexPath) as! SwitchSettingCell
            
            switchCell.configure(with: option)
            return switchCell
            
        case .accountOption(let option):
            let accountCell = tableView.dequeueReusableCell(withIdentifier: SignedInAccountSettingCell.IDENTIFIER, for: indexPath) as! SignedInAccountSettingCell
            
            accountCell.configure(with: option)
            return accountCell
        }
    }
}
