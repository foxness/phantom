//
//  AboutViewController.swift
//  Phantom
//
//  Created by River on 2021/08/16.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AboutViewDelegate {
    @IBOutlet weak var appIconView: UIImageView!
    @IBOutlet weak var aboutHeaderView: UIView!
    
    @IBOutlet private var tableView: UITableView!
    
    private var presenter = AboutPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter.attachView(self)
        setupViews()
        presenter.viewDidLoad()
    }
    
    func setupViews() {
        tintAppIcon()
        
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 300
        tableView.register(AboutHeader.self, forHeaderFooterViewReuseIdentifier: AboutHeader.IDENTIFIER)
        
        tableView.delegate = self
        tableView.dataSource = self
        
//        tableView.contentInset = UIEdgeInsets(top: 100, left: 0, bottom: 0, right: 0) // todo: programmaticaly get this number
    }
    
    func tintAppIcon() {
        appIconView.makeTintable()
        
        // uncomment for black&white icon
//        appIconView.tintColor = UIColor.label
    }
    
    func showEmailComposer(to email: String, subject: String? = nil, body: String? = nil) {
        guard let url = Helper.generateEmailUrl(to: email, subject: subject, body: body) else { return }
//        guard UIApplication.shared.canOpenURL(url) else { return } // I don't think this is needed since open(url) seems to be failing gracefully
        
        UIApplication.shared.open(url)
    }
    
    func open(url: URL) {
        UIApplication.shared.open(url)
    }
    
    // MARK: - Table
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presenter.getItemCount()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        presenter.didSelectItem(at: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let aboutHeader = tableView.dequeueReusableHeaderFooterView(withIdentifier: AboutHeader.IDENTIFIER) as! AboutHeader
        aboutHeader.addAboutHeaderView(aboutHeaderView)

        return aboutHeader
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = presenter.getItem(at: indexPath.row)
        switch item {
        case .linkItem(let linkItem):
            let linkCell = tableView.dequeueReusableCell(withIdentifier: LinkAboutCell.IDENTIFIER, for: indexPath) as! LinkAboutCell
            
            linkCell.configure(with: linkItem)
            return linkCell
            
        case .textItem(let textItem):
            let textCell = tableView.dequeueReusableCell(withIdentifier: TextAboutCell.IDENTIFIER, for: indexPath) as! TextAboutCell
            
            textCell.configure(with: textItem)
            return textCell
        }
    }
}
