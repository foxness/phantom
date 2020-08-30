//
//  MainViewController.swift
//  Phantom
//
//  Created by user179800 on 8/30/20.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
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
        let post = Post(title: "testy is besty", content: "content mccontentface", subreddit: "test")
        reddit.submitPost(post) { (url) in
            let url = url!
            Util.p("url", url)
        }
    }
}
