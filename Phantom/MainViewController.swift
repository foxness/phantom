//
//  MainViewController.swift
//  Phantom
//
//  Created by user179800 on 8/30/20.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import UIKit
import Schedule

class MainViewController: UIViewController {
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var subredditField: UITextField!
    
    var redditLoggedIn = false
    var database: Database = .instance
    
    var reddit: Reddit?

    func loginReddit(with reddit: Reddit) {
        self.reddit = reddit
        Log.p("i logged in reddit")
        
        // todo: remove the previous view controllers from the navigation stack
        
        redditLoggedIn = true
    }
    
    func saveData() {
        database.postTitle = titleField.text!
        database.postText = textField.text!
        database.postSubreddit = subredditField.text!
        
        if reddit != nil {
            database.redditRefreshToken = reddit?.refreshToken
            database.redditAccessToken = reddit?.accessToken
            database.redditAccessTokenExpirationDate = reddit?.accessTokenExpirationDate
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let refreshToken = database.redditRefreshToken
        let accessToken = database.redditAccessToken
        let accessTokenExpirationDate = database.redditAccessTokenExpirationDate
        
        if refreshToken != nil {
            reddit = Reddit(refreshToken: refreshToken,
                            accessToken: accessToken,
                            accessTokenExpirationDate: accessTokenExpirationDate)
            
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
    
    var task: Task?
    
    func scheduleTask() {
        let work = {
            let notification = Notifications.make(title: "hello there, I'm doing work", body: "asd")
            Notifications.send(notification)
        }
        
        let plan = Plan.after(10.seconds)
        task = plan.do(action: work)
        
    }
    
    @IBAction func notificationButtonPressed(_ sender: Any) {
        Notifications.requestPermissions {
            Notifications.send(Notifications.make())
        }
    }
    
    @IBAction func scheduleButtonPressed(_ sender: Any) {
        scheduleTask()
    }
    
    @IBAction func submitPostButtonPressed(_ sender: Any) {
        let title = titleField.text!
        let content = textField.text!
        let subreddit = subredditField.text!
        
        let post = Post(title: title, content: content, subreddit: subreddit)
        reddit!.submit(post: post) { (url) in
            let url = url!
            
            DispatchQueue.main.async { self.showToast(url) }
            Log.p("url", url)
        }
    }
    
    @IBAction func unwindToMain(unwindSegue: UIStoryboardSegue) {
        Log.p("unwind to main")
    }
}
