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
    
    private var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
    }
    
    func setupViews() {
        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.frame = view.bounds
        tableView.register(SettingCell.self, forCellReuseIdentifier: SettingCell.IDENTIFIER)
        
        view.addSubview(tableView)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presenter.getOptionCount()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingCell.IDENTIFIER, for: indexPath) as! SettingCell
        let option = presenter.getOption(at: indexPath.row)
        
        cell.configure(with: option)
        return cell
    }
}
