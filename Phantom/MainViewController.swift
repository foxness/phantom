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
    
    var initialized = false
    var database: Database = .instance
    
    var reddit: Reddit!

    func initialize(with reddit: Reddit) {
        self.reddit = reddit
        Log.p("i was initialized with reddit")
        
        // todo: remove the previous view controllers from the navigation stack
        
        initialized = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // next todo: determine if reddit is logged in and if so initialize reddit here
        
        Log.p("BuildVersionNumber", Bundle.main.buildVersionNumber)
        Log.p("Release", Bundle.main.releaseVersionNumber)
        Log.p("identifier", Bundle.main.bundleIdentifier!)
        
        titleField.text = database.postTitle
        textField.text = database.postText
        subredditField.text = database.postSubreddit
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !initialized {
            performSegue(withIdentifier: "mainToIntroduction", sender: nil)
            Log.p("segue from main to introduction")
        }
    }
    
    @IBAction func submitPostButtonPressed(_ sender: Any) {
        let title = titleField.text!
        let content = textField.text!
        let subreddit = subredditField.text!
        
        let post = Post(title: title, content: content, subreddit: subreddit)
        reddit.submit(post: post) { (url) in
            let url = url!
            
            DispatchQueue.main.async { self.showToast(url) }
            Log.p("url", url)
        }
    }
    
    @IBAction func titleEditingEnded(_ sender: Any) {
        database.postTitle = titleField.text!
    }
    
    @IBAction func textEditingEnded(_ sender: Any) {
        database.postText = textField.text!
    }
    
    @IBAction func subredditEditingEnded(_ sender: Any) {
        database.postSubreddit = subredditField.text!
    }
    
    @IBAction func unwindToMain(unwindSegue: UIStoryboardSegue) {
        Log.p("unwind to main")
    }
}
