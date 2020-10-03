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
    
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var subredditField: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var newPost = false
    var post: Post?
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        guard let button = sender as? UIBarButtonItem, button === saveButton else {
            Log.p("this didnt work")
            return
        }
        
        let id = post!.id
        let title = titleField.text!
        let text = textField.text!
        let subreddit = subredditField.text!
        let date = datePicker.date
        
        post = Post.Link(id: id, title: title, subreddit: subreddit, date: date, url: text)
    }
    
    func updateSaveButton() {
        let title = titleField.text!
        let text = textField.text!
        let subreddit = subredditField.text!
        
        let isPostValid = Post.isValid(title: title, subreddit: subreddit, type: .link, text: nil, url: text)
        saveButton.isEnabled = isPostValid
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if post == nil {
            newPost = true
            Log.p("new post")
            
            let title = ""
            let subreddit = "test"
            let date = Date() + 1 * 60
            let url = ""
            
            post = Post.Link(title: title, subreddit: subreddit, date: date, url: url)
            
            navigationItem.title = PostViewController.TEXT_NEW_POST_TITLE
        }
        
        titleField.text = post!.title
        textField.text = post!.url
        subredditField.text = post!.subreddit
        datePicker.date = post!.date
        
        updateSaveButton()
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
    
    @IBAction func titleChanged(_ sender: Any) { updateSaveButton() }
    @IBAction func textChanged(_ sender: Any) { updateSaveButton() }
    @IBAction func subredditChanged(_ sender: Any) { updateSaveButton() }
}
