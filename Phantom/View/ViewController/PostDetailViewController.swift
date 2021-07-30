//
//  PostDetailViewController.swift
//  Phantom
//
//  Created by Rivershy on 2020/08/30.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import UIKit

// todo: add paste button for url field
// todo: todo add "/r/" in inside subreddit field

class PostDetailViewController: UIViewController, PostDetailViewDelegate {
    enum Segue: String {
        case unwindPostSaved = "unwindPostSaved"
    }
    
    private static let TEXT_NEW_POST_TITLE = "New Post"
    private static let TEXT_SELF_PLACEHOLDER = "Add text (optional)"
    private static let TEXT_LINK_PLACEHOLDER = "Add URL"
    
    @IBOutlet weak var typeControl: UISegmentedControl!
    
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var contentField: UITextField!
    @IBOutlet weak var subredditField: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var subredditPrefixLabel: UILabel!
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    private let presenter = PostDetailPresenter()
    
    var postTitle: String {
        return PostDetailViewController.emptyIfNull(titleField.text?.trim())
    }
    
    var postSubreddit: String {
        return PostDetailViewController.emptyIfNull(subredditField.text?.trim())
    }
    
    var postDate: Date {
        return datePicker.date
    }
    
    var postType: Post.PostType {
        return typeControl.selectedSegmentIndex == 0 ? .link : .text
    }
    
    var postUrl: String? {
        return contentField.text?.trim()
    }
    
    var postText: String? {
        return contentField.text?.trim()
    }
    
    func setSaveButton(enabled: Bool) {
        saveButton.isEnabled = enabled
    }
    
    func supplyPost(_ post: Post) {
        presenter.postSupplied(post)
    }
    
    func getResultingPost() -> (post: Post, isNewPost: Bool) {
        return (post: presenter.resultingPost, isNewPost: presenter.isNewPost)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        setupTextFieldBottomLines()
        
        presenter.attachView(self)
        presenter.viewDidLoad()
    }
    
//    private func setupTextFieldBottomLines() {
//        let bottomLine = CALayer()
//        bottomLine.frame = CGRect(x: 0, y: titleField.frame.height - 2, width: titleField.layer.frame.width - 50, height: 2)
//        bottomLine.backgroundColor = view.tintColor.cgColor
//        titleField.layer.addSublayer(bottomLine)
//    }
    
    func indicateNewPost() {
        navigationItem.title = PostDetailViewController.TEXT_NEW_POST_TITLE
    }
    
    func displayPost(_ post: Post) {
        titleField.text = post.title
        datePicker.date = post.date
        
        subredditField.text = post.subreddit
        updateSubredditPrefix()
        
        let content: String?
        let segmentIndex: Int
        switch post.type {
        case .text:
            content = post.text
            segmentIndex = 1
        case .link:
            content = post.url
            segmentIndex = 0
        }
        
        contentField.text = content
        typeControl.selectedSegmentIndex = segmentIndex
        
        updateContentPlaceholder()
    }
    
    private func updateContentPlaceholder() {
        let contentPlaceholder: String
        
        switch typeControl.selectedSegmentIndex {
        case 1:
            contentPlaceholder = PostDetailViewController.TEXT_SELF_PLACEHOLDER
        case 0:
            contentPlaceholder = PostDetailViewController.TEXT_LINK_PLACEHOLDER
        default:
            fatalError()
        }
        
        contentField.placeholder = contentPlaceholder
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        guard let button = sender as? UIBarButtonItem, button === saveButton else {
            Log.p("this didnt work")
            return
        }
        
        presenter.saveButtonPressed()
    }
    
    func dismiss() {
        let animated = true
        
        let presentingInAddMode = presentingViewController is UINavigationController
        if presentingInAddMode {
            dismiss(animated: animated, completion: nil)
        } else if let owningNavigationController = navigationController {
            owningNavigationController.popViewController(animated: animated)
        } else {
            fatalError("The PostViewController is not inside a navigation controller")
        }
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        presenter.cancelButtonPressed()
    }
    
    @IBAction func typeChanged(_ sender: UISegmentedControl) {
        updateContentPlaceholder()
        presenter.postTypeChanged()
    }
    
    @IBAction func titleChanged(_ sender: Any) {
        presenter.titleChanged()
    }
    
    @IBAction func textChanged(_ sender: Any) {
        presenter.textChanged()
    }
    
    @IBAction func subredditChanged(_ sender: Any) {
        updateSubredditPrefix()
        presenter.subredditChanged()
    }
    
    private func updateSubredditPrefix() {
        subredditPrefixLabel.isHidden = PostDetailViewController.emptyIfNull(subredditField.text).trim().isEmpty
    }
    
    private static func emptyIfNull(_ str: String?) -> String { // todo: extract into extensions
        return str ?? ""
    }
}
