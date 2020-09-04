//
//  MainViewController.swift
//  Phantom
//
//  Created by user179800 on 8/30/20.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import UIKit

class PostViewController: UIViewController {
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var subredditField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
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
        
        post = Post(title: title, content: text, subreddit: subreddit)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if post == nil {
            let title = ""
            let text = ""
            let subreddit = "test"
            
            post = Post(title: title, content: text, subreddit: subreddit)
        }
        
        titleField.text = post!.title
        textField.text = post!.content
        subredditField.text = post!.subreddit
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func notificationButtonPressed(_ sender: Any) {
        //Notifications.requestPermissions {
        //    Notifications.send(Notifications.make())
        //}
    }
    
    @IBAction func scheduleButtonPressed(_ sender: Any) {
        //let date = Date(timeIntervalSinceNow: 12)
        //PostScheduler.schedulePostTask(earliestBeginDate: date)
    }
    
    @IBAction func submitPostButtonPressed(_ sender: Any) {
        /*saveData()
        
        submitter?.submitPost(post) { (url) in
            let url = url!
            
            DispatchQueue.main.async { self.showToast(url) }
            Log.p("url", url)
        }*/
    }
}
