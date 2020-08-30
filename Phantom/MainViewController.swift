//
//  MainViewController.swift
//  Phantom
//
//  Created by user179800 on 8/30/20.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var subredditField: UITextField!
    
    var reddit: Reddit!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //
    }
    
    func initialize(with reddit: Reddit) {
        self.reddit = reddit
        Util.p("i was initialized with reddit")
        
        // todo: remove the previous view controllers from the navigation stack
    }
    
    @IBAction func submitButtonPressed(_ sender: Any) {
        submitPost()
    }
    
    func submitPost() {
        let title = titleField.text!
        let content = textField.text!
        let subreddit = subredditField.text!
        
        let post = Post(title: title, content: content, subreddit: subreddit)
        reddit.submitPost(post) { (url) in
            let url = url!
            
            DispatchQueue.main.async { self.showToast(url) }
            Util.p("url", url)
        }
    }
}
