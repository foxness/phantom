//
//  SettingsViewController.swift
//  Phantom
//
//  Created by River on 2021/06/11.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import UIKit

// todo: add settings for reddit resubmit & sendReplies
// todo: add settings for retry strategy

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SettingsViewDelegate, RedditSignInReceiver, ImgurSignInReceiver {
    enum Segue: String {
        case showRedditSignIn = "settingsShowRedditSignIn"
        case showImgurSignIn = "settingsShowImgurSignIn"
    }
    
    @IBOutlet private var tableView: UITableView!
    
    private var presenter = SettingsPresenter()
    
    weak var delegate: SettingsDelegate? {
        get { presenter.delegate }
        set { presenter.delegate = newValue }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter.attachView(self)
        setupViews()
        presenter.viewDidLoad()
    }
    
    func setupViews() {
//        tableView.rowHeight = UITableView.automaticDimension
//        tableView.estimatedRowHeight = 50
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func showBulkAddSubredditAlert(currentSubreddit: String) {
        let title = "Set subreddit"
        let placeholder = "Bulk Add Subreddit"
        let message: String? = nil
        let saveTitle = "Save"
        let cancelTitle = "Cancel"
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alertController.view.tintColor = view.tintColor
        
        var textField: UITextField? = nil
        
        alertController.addTextField { (textField_ : UITextField!) -> Void in
            textField_.placeholder = placeholder
            textField_.text = currentSubreddit
            
            textField = textField_
        }
        
        let presentCompletion = { () -> Void in
            textField?.selectAll(nil)
        }
        
        let saveHandler = { (action: UIAlertAction) -> Void in
            let textField = alertController.textFields![0] as UITextField
            let subreddit = textField.text
            
            self.presenter.bulkAddSubredditSet(subreddit)
        }
        
        let saveAction = UIAlertAction(title: saveTitle, style: UIAlertAction.Style.default, handler: saveHandler)
        let cancelAction = UIAlertAction(title: cancelTitle, style: UIAlertAction.Style.default, handler: nil)
        
        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)
        
        present(alertController, animated: true, completion: presentCompletion)
    }
    
    func showInvalidSubredditAlert(tryAgainHandler: (() -> Void)?) {
        let title = "Invalid subreddit name"
        let message: String? = nil
        let okTitle = "OK"
        
        let handler = { (action: UIAlertAction) -> Void in
            tryAgainHandler?()
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: okTitle, style: .default, handler: handler)
        
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    func segueToRedditSignIn() {
        segueTo(.showRedditSignIn)
    }
    
    func segueToImgurSignIn() {
        segueTo(.showImgurSignIn)
    }
    
    private func segueTo(_ segue: Segue) { // todo: extract this from VCs?
        performSegue(withIdentifier: segue.rawValue, sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch Segue(rawValue: segue.identifier ?? "") {
        case .showRedditSignIn,
             .showImgurSignIn:
            break
            
        default:
            fatalError()
        }
    }
    
    @IBAction func unwindRedditSignIn(unwindSegue: UIStoryboardSegue) {
        guard unwindSegue.identifier == RedditSignInViewController.Segue.unwindRedditSignedIn.rawValue else {
            fatalError("Got unexpected unwind segue")
        }
    }
    
    @IBAction func unwindImgurSignIn(unwindSegue: UIStoryboardSegue) {
        guard unwindSegue.identifier == ImgurSignInViewController.Segue.unwindImgurSignedIn.rawValue else {
            fatalError("Got unexpected unwind segue")
        }
    }
    
    func redditSignedIn(with reddit: Reddit) {
        presenter.redditSignedIn(reddit)
        
        // todo: remove the previous view controllers from the navigation stack
    }
    
    func imgurSignedIn(with imgur: Imgur) {
        presenter.imgurSignedIn(imgur)
    }
    
    func reloadSettingCell(section: Int, at index: Int) {
        let indexPath = IndexPath(row: index, section: section)
        tableView.reloadRows(at: [indexPath], with: .fade)
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
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let selectable = presenter.isSelectableOption(section: indexPath.section, at: indexPath.row)
        return selectable ? indexPath : nil
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
            if option.signedIn {
                let signedInCell = tableView.dequeueReusableCell(withIdentifier: SignedInAccountSettingCell.IDENTIFIER, for: indexPath) as! SignedInAccountSettingCell
                
                signedInCell.configure(with: option)
                return signedInCell
            }
            
            let signedOutCell = tableView.dequeueReusableCell(withIdentifier: SignedOutAccountSettingCell.IDENTIFIER, for: indexPath) as! SignedOutAccountSettingCell
            
            signedOutCell.configure(with: option)
            return signedOutCell
        
        case .textOption(let option):
            let textCell = tableView.dequeueReusableCell(withIdentifier: TextSettingCell.IDENTIFIER, for: indexPath) as! TextSettingCell
            
            textCell.configure(with: option)
            return textCell
        }
    }
}
