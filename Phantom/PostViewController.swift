//
//  MainViewController.swift
//  Phantom
//
//  Created by user179800 on 8/30/20.
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
        
        let title = titleField.text!
        let text = textField.text!
        let subreddit = subredditField.text!
        let date = datePicker.date
        
        post = Post(title: title, text: text, subreddit: subreddit, date: date)
    }
    
    func updateSaveButton() {
        let title = titleField.text!
        let text = textField.text!
        let subreddit = subredditField.text!
        
        let isPostValid = Post.isValid(title: title, text: text, subreddit: subreddit)
        saveButton.isEnabled = isPostValid
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if post == nil {
            newPost = true
            
            let title = ""
            let text = ""
            let subreddit = "test"
            let date = Date() + 1 * 60
            
            post = Post(title: title, text: text, subreddit: subreddit, date: date)
            
            navigationItem.title = PostViewController.TEXT_NEW_POST_TITLE
        }
        
        titleField.text = post!.title
        textField.text = post!.text
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
