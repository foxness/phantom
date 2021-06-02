//
//  PostViewController.swift
//  Phantom
//
//  Created by Rivershy on 2020/08/30.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import UIKit

class PostViewController: UIViewController, PostViewDelegate {
    enum Segue: String { // todo: move away from auto string segue enums to 'backSavePost = "backSavePost"'?
        case backSavePost // post to list
    }
    
    static let TEXT_NEW_POST_TITLE = "New Post"
    
    @IBOutlet weak var typeControl: UISegmentedControl!
    
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var contentField: UITextField!
    @IBOutlet weak var subredditField: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    private let presenter = PostPresenter()
    
    var postTitle: String {
        return PostViewController.emptyIfNull(titleField.text?.trim())
    }
    
    var postSubreddit: String {
        return PostViewController.emptyIfNull(subredditField.text?.trim())
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
        
        presenter.attachView(self)
        
        presenter.viewDidLoad()
    }
    
    func indicateNewPost() {
        navigationItem.title = PostViewController.TEXT_NEW_POST_TITLE
    }
    
    func displayPost(_ post: Post) {
        titleField.text = post.title
        subredditField.text = post.subreddit
        datePicker.date = post.date
        
        let content: String?
        let segmentIndex: Int
        switch post.type {
        case .text:
            content = post.text
            segmentIndex = 1
        case .link:
            content = post.url // todo: add paste button
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
            contentPlaceholder = "Text"
        case 0:
            contentPlaceholder = "Link"
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
        presenter.subredditChanged()
    }
    
    private static func emptyIfNull(_ str: String?) -> String {
        return str ?? ""
    }
}
