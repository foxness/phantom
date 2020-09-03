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
    
    var redditLoggedIn = false
    var database: Database = .instance
    
    var submitter: PostSubmitter?

    func loginReddit(with reddit: Reddit) {
        self.submitter = PostSubmitter(reddit: reddit)
        Log.p("i logged in reddit")
        
        // todo: remove the previous view controllers from the navigation stack
        
        redditLoggedIn = true
    }
    
    func saveData() {
        database.postTitle = titleField.text!
        database.postText = textField.text!
        database.postSubreddit = subredditField.text!
        
        if submitter != nil {
            database.redditRefreshToken = submitter?.reddit.refreshToken
            database.redditAccessToken = submitter?.reddit.accessToken
            database.redditAccessTokenExpirationDate = submitter?.reddit.accessTokenExpirationDate
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let refreshToken = database.redditRefreshToken
        let accessToken = database.redditAccessToken
        let accessTokenExpirationDate = database.redditAccessTokenExpirationDate
        
        if refreshToken != nil {
            let reddit = Reddit(refreshToken: refreshToken,
                            accessToken: accessToken,
                            accessTokenExpirationDate: accessTokenExpirationDate)
            
            submitter = PostSubmitter(reddit: reddit)
            
            redditLoggedIn = true
            Log.p("found logged reddit in database")
        }
        
        titleField.text = database.postTitle
        textField.text = database.postText
        subredditField.text = database.postSubreddit
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !redditLoggedIn {
            performSegue(withIdentifier: "mainToIntroduction", sender: nil)
            Log.p("segue from main to introduction")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveData()
    }
    
    @IBAction func notificationButtonPressed(_ sender: Any) {
        Notifications.requestPermissions {
            Notifications.send(Notifications.make())
        }
    }
    
    @IBAction func scheduleButtonPressed(_ sender: Any) {
        let date = Date(timeIntervalSinceNow: 12)
        PostScheduler.schedulePostTask(earliestBeginDate: date)
    }
    
    @IBAction func submitPostButtonPressed(_ sender: Any) {
        let title = titleField.text!
        let content = textField.text!
        let subreddit = subredditField.text!
        
        let post = Post(title: title, content: content, subreddit: subreddit)
        
        submitter?.submitPost(post) { (url) in
            let url = url!
            
            DispatchQueue.main.async { self.showToast(url) }
            Log.p("url", url)
        }
    }
    
    @IBAction func unwindToMain(unwindSegue: UIStoryboardSegue) {
        Log.p("unwind to main")
    }
}
