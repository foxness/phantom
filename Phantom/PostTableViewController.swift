//
//  PostTableViewController.swift
//  Phantom
//
//  Created by user179800 on 9/4/20.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import UIKit

class PostTableViewController: UITableViewController {
    var redditLoggedIn = false
    var database: Database = .instance
    
    var submitter: PostSubmitter?

    func loginReddit(with reddit: Reddit) {
        self.submitter = PostSubmitter(reddit: reddit)
        Log.p("i logged in reddit")
        
        // todo: remove the previous view controllers from the navigation stack
        
        redditLoggedIn = true
    }
    
    var posts: [Post] = [Post]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
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
        
        loadPostsFromDatabase()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !redditLoggedIn {
            performSegue(withIdentifier: "postListToIntroduction", sender: nil)
            Log.p("segue from main to introduction")
        }
    }
    
    func saveData() {
        if submitter != nil {
            database.redditRefreshToken = submitter?.reddit.refreshToken
            database.redditAccessToken = submitter?.reddit.accessToken
            database.redditAccessTokenExpirationDate = submitter?.reddit.accessTokenExpirationDate
        }
        
        database.posts = posts
        database.save()
        Log.p("i saved data")
    }
    
    func loadPostsFromDatabase() {
        posts = database.posts
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { posts.count }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PostCell.IDENTIFIER, for: indexPath) as! PostCell
        let post = posts[indexPath.row]
        
        cell.set(post: post)
        return cell
    }
    
    @IBAction func unwindToPostList(unwindSegue: UIStoryboardSegue) {
        if let pvc = unwindSegue.source as? PostViewController, let post = pvc.post { //
            if let selectedIndexPath = tableView.indexPathForSelectedRow { // user was editing a post
                posts[selectedIndexPath.row] = post
                tableView.reloadRows(at: [selectedIndexPath], with: .none)
            } else { // user added a new post
                let newIndexPath = IndexPath(row: posts.count, section: 0)
                posts.append(post)
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }
        } else { // used returned from introduction/login
            //
        }
        
        saveData()
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch segue.identifier ?? "" {
        case "addItem":
            Log.p("adding item")
            
        case "showDetail":
            let dest = segue.destination as! PostViewController
            let selectedCell = sender as! PostCell
            let indexPath = tableView.indexPath(for: selectedCell)!
            let selectedPost = posts[indexPath.row]
            dest.post = selectedPost
            
        default:
            fatalError("Unexpected segue identifier: \(segue.identifier)")
        }
    }
}
