//
//  PostViewController.swift
//  Phantom
//
//  Created by Rivershy on 2020/08/30.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import UIKit

class PostViewController: UIViewController {
    static let SEGUE_BACK_POST_TO_LIST = "backSavePost"
    
    static let TEXT_NEW_POST_TITLE = "New Post"
    
    @IBOutlet weak var typeControl: UISegmentedControl!
    
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var contentField: UITextField!
    @IBOutlet weak var subredditField: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var newPost = false
    var post: Post?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if post == nil {
            newPost = true
            Log.p("new post")
            post = PostViewController.getDefaultPost()
            navigationItem.title = PostViewController.TEXT_NEW_POST_TITLE
        }
        
        updateUi(for: post!)
        updateSaveButton()
    }
    
    private func updateUi(for post: Post) {
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
        
        savePost()
    }
    
    private func getPostType() -> Post.PostType {
        return typeControl.selectedSegmentIndex == 0 ? .link : .text
    }
    
    private func constructPost() -> Post {
        let id = post!.id
        let title = titleField.text!
        let subreddit = subredditField.text!
        let date = datePicker.date
        
        let postType = getPostType()
        let post: Post
        
        switch postType {
        case .link:
            let url = contentField.text!
            post = Post.Link(id: id, title: title, subreddit: subreddit, date: date, url: url)
        case .text:
            let text = contentField.text!
            post = Post.Text(id: id, title: title, subreddit: subreddit, date: date, text: text)
        }
        
        return post
    }
    
    private func savePost() {
        self.post = constructPost()
    }
    
    private func updateSaveButton() {
        let post = constructPost()
        let isPostValid = post.isValid()
        saveButton.isEnabled = isPostValid
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
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
    
    @IBAction func typeChanged(_ sender: UISegmentedControl) {
        updateContentPlaceholder()
        updateSaveButton()
    }
    
    @IBAction func titleChanged(_ sender: Any) { updateSaveButton() }
    @IBAction func textChanged(_ sender: Any) { updateSaveButton() }
    @IBAction func subredditChanged(_ sender: Any) { updateSaveButton() }
    
    private static func getDefaultPost() -> Post {
        let title = ""
        let subreddit = "test"
        let date = Date() + 1 * 60
        let url = ""
        
        return Post.Link(title: title, subreddit: subreddit, date: date, url: url)
    }
}
