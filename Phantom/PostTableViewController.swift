//
//  PostTableViewController.swift
//  Phantom
//
//  Created by user179800 on 9/4/20.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import UIKit

class PostTableViewController: UITableViewController {
    static let SEGUE_SHOW_INTRODUCTION = "showIntroduction"
    static let SEGUE_ADD_POST = "addPost"
    static let SEGUE_EDIT_POST = "editPost"
    
    static let TEXT_INDICATOR_SUBMITTING = "Submitting..."
    static let TEXT_INDICATOR_DONE = "Done!"
    
    static let COLOR_INDICATOR_SUBMITTING = UIColor.systemBlue
    static let COLOR_INDICATOR_DONE = UIColor.systemGreen
    
    static let DURATION_INDICATOR_DONE = 1.5
    
    var redditLoggedIn = false
    var database: Database = .instance
    var submitter: PostSubmitter?
    var posts = [Post]()
    
    @IBOutlet var submissionIndicatorView: UIView!
    @IBOutlet weak var submissionIndicatorLabel: UILabel!
    @IBOutlet weak var submissionIndicatorActivity: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addSubmissionIndicatorView()
        
        // self.clearsSelectionOnViewWillAppear = false
        
        setupPostSubmitter()
        loadPostsFromDatabase()
    }
    
    func loginReddit(with reddit: Reddit) {
        self.submitter = PostSubmitter(reddit: reddit)
        Log.p("i logged in reddit")
        
        // todo: remove the previous view controllers from the navigation stack
        
        redditLoggedIn = true
    }
    
    func setupPostSubmitter() {
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
    }
    
    func addSubmissionIndicatorView() {
        // used: https://stackoverflow.com/questions/4641879/how-to-add-a-uiview-above-the-current-uitableviewcontroller
        
        let navController = navigationController!
        let navBar = navController.navigationBar
        
        // why take navigation controller's view?
        // because if I use self.view for some reason the subview is interaction-transparent
        // it means touches go through it making it unable to be interacted with
        let superview = navController.view!
        
        superview.addSubview(submissionIndicatorView)
        submissionIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        let constraints = [submissionIndicatorView.widthAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.widthAnchor),
                           submissionIndicatorView.heightAnchor.constraint(equalToConstant: submissionIndicatorView.bounds.size.height),
                           submissionIndicatorView.centerXAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.centerXAnchor),
                           submissionIndicatorView.topAnchor.constraint(equalTo: navBar.safeAreaLayoutGuide.bottomAnchor)]
        NSLayoutConstraint.activate(constraints)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        //view.bringSubviewToFront(submissionIndicatorView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !redditLoggedIn {
            performSegue(withIdentifier: PostTableViewController.SEGUE_SHOW_INTRODUCTION, sender: nil)
        }
    }
    
    func saveData() {
        saveRedditAuth()
        savePosts()
    }
    
    func saveRedditAuth() {
        if submitter != nil {
            database.redditRefreshToken = submitter?.reddit.refreshToken
            database.redditAccessToken = submitter?.reddit.accessToken
            database.redditAccessTokenExpirationDate = submitter?.reddit.accessTokenExpirationDate
        }
    }
    
    func savePosts() {
        database.posts = posts
        database.savePosts()
    }
    
    func loadPostsFromDatabase() {
        posts = database.posts
    }
    
    func setSubmissionIndicator(start: Bool) {
        // todo: handle multiple simultaneous submit actions
        assert(submissionIndicatorView.isHidden == start)
        
        func set(show: Bool) { submissionIndicatorView.isHidden = !show }
        
        submissionIndicatorActivity.isHidden = !start
        submissionIndicatorLabel.text = start ? PostTableViewController.TEXT_INDICATOR_SUBMITTING
            : PostTableViewController.TEXT_INDICATOR_DONE
        submissionIndicatorView.backgroundColor = start ? PostTableViewController.COLOR_INDICATOR_SUBMITTING
            : PostTableViewController.COLOR_INDICATOR_DONE
        
        if start {
            set(show: true)
        } else {
            let disappearTime = DispatchTime.now() + PostTableViewController.DURATION_INDICATOR_DONE
            DispatchQueue.main.asyncAfter(deadline: disappearTime) { set(show: false) }
        }
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
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool { true }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            posts.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            savePosts()
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }

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
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let style = UIContextualAction.Style.normal
        let title = "Submit"
        let bgColor = UIColor.systemIndigo
        
        let handler = { (action: UIContextualAction, sourceView: UIView, completion: @escaping (Bool) -> Void) in
            self.setSubmissionIndicator(start: true)
            
            let post = self.posts[indexPath.row]
            
            self.submitter!.submitPost(post) { url in
                //self.showToast("url: \(String(describing: url))")
                Log.p("url: \(String(describing: url))")
                
                DispatchQueue.main.async {
                    self.setSubmissionIndicator(start: false)
                }
            }
            
            let actionPerformed = true
            completion(actionPerformed)
        }
        
        let submitAction = UIContextualAction(style: style, title: title, handler: handler)
        submitAction.backgroundColor = bgColor
        
        let config = UISwipeActionsConfiguration(actions: [submitAction])
        return config
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch segue.identifier ?? "" {
        case PostTableViewController.SEGUE_ADD_POST:
            Log.p("adding post")
            
        case PostTableViewController.SEGUE_EDIT_POST:
            let dest = segue.destination as! PostViewController
            let selectedCell = sender as! PostCell
            let indexPath = tableView.indexPath(for: selectedCell)!
            let selectedPost = posts[indexPath.row]
            dest.post = selectedPost
            
        case PostTableViewController.SEGUE_SHOW_INTRODUCTION:
            Log.p("showing introduction")
            
        default:
            fatalError()
        }
    }
    
    @IBAction func unwindToPostList(unwindSegue: UIStoryboardSegue) {
        switch unwindSegue.identifier ?? "" {
        case PostViewController.SEGUE_BACK_POST_TO_LIST:
            if let pvc = unwindSegue.source as? PostViewController, let post = pvc.post { //
                if let selectedIndexPath = tableView.indexPathForSelectedRow { // user was editing a post
                    posts[selectedIndexPath.row] = post
                    tableView.reloadRows(at: [selectedIndexPath], with: .none)
                } else { // user added a new post
                    let newIndexPath = IndexPath(row: posts.count, section: 0)
                    posts.append(post)
                    tableView.insertRows(at: [newIndexPath], with: .automatic)
                }
                savePosts()
            } else {
                fatalError()
            }
        case LoginViewController.SEGUE_BACK_LOGIN_TO_LIST:
            saveRedditAuth()
        default:
            fatalError()
        }
    }
}
