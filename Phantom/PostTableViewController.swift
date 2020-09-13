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
    
    var disableSubmission = false // needed to prevent multiple post submission
    var disabledPostId: UUID? // needed to disable editing segues for submitting post
    
    var posts = [Post]()
    
    @IBOutlet var submissionIndicatorView: UIView!
    @IBOutlet weak var submissionIndicatorLabel: UILabel!
    @IBOutlet weak var submissionIndicatorActivity: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addSubmissionIndicatorView()
        setupPostSubmitter()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        Log.p("loaded posts")
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Notifications.requestPermissions { granted, error in
            if !granted {
                Log.p("permissions not granted :0")
            }
            
            if let error = error {
                Log.p("permissions error", error)
            }
        }
        
        if !redditLoggedIn {
            performSegue(withIdentifier: PostTableViewController.SEGUE_SHOW_INTRODUCTION, sender: nil)
        }
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
        sortPosts()
    }
    
    func sortPosts() {
        posts.sort { $0.date < $1.date }
    }
    
    func setSubmissionIndicator(start: Bool, onDisappear: (() -> Void)? = nil) {
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
            DispatchQueue.main.asyncAfter(deadline: disappearTime) {
                set(show: false)
                onDisappear?()
            }
        }
    }

    // MARK: - Table view data source
    
    func addNewPost(_ post: Post, with animation: UITableView.RowAnimation = .top) {
        PostNotifier.notify(for: post)
        
        posts.append(post)
        sortPosts()
        
        let row = posts.firstIndex(of: post)!
        let newIndexPath = IndexPath(row: row, section: 0)
        
        tableView.insertRows(at: [newIndexPath], with: animation)
        savePosts()
    }
    
    func editPost(index: IndexPath, post: Post) {
        PostNotifier.notify(for: post)
        
        posts[index.row] = post
        sortPosts()
        
        tableView.reloadData()
        savePosts()
    }
    
    func deletePost(index: IndexPath, with animation: UITableView.RowAnimation = .none, cancelNotify: Bool = true) {
        let post = posts.remove(at: index.row)
        
        if cancelNotify {
            PostNotifier.cancel(for: post)
        }
        
        tableView.deleteRows(at: [index], with: animation)
        savePosts()
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { posts.count }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PostCell.IDENTIFIER, for: indexPath) as! PostCell
        let post = posts[indexPath.row]
        
        cell.set(post: post)
        return cell
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deletePost(index: indexPath)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    // prevents post submission and deletion while a post is being submitted
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let disabledPostId = disabledPostId else { return true }
        
        let postId = posts[indexPath.row].id
        return postId != disabledPostId
    }
    
    // prevents post editing segue while a post is being submitted
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let disabledPostId = disabledPostId else { return indexPath }
        
        let postId = posts[indexPath.row].id
        return postId == disabledPostId ? nil : indexPath
    }
    
    func submitPressed(postIndex: IndexPath) {
        disableSubmission = true
        
        let post = posts[postIndex.row]
        PostNotifier.cancel(for: post)
        
        disabledPostId = post.id // make the post uneditable
        setSubmissionIndicator(start: true) // let the user know
        
        submitter!.submitPost(post) { url in
            Log.p("url: \(String(describing: url))")
            
            DispatchQueue.main.async {
                let success = url != nil
                if success {
                    self.deletePost(index: postIndex, with: .right, cancelNotify: false) // because already cancelled
                } else {
                    PostNotifier.notify(for: post)
                }
                
                self.disabledPostId = nil // make editable
                self.setSubmissionIndicator(start: false) {
                    // when the indicator disappears:
                    self.disableSubmission = false
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !disableSubmission else { return UISwipeActionsConfiguration() } // this prevents multiple post submission
        
        let style = UIContextualAction.Style.normal
        let title = "Submit"
        let bgColor = UIColor.systemIndigo
        
        let handler = { (action: UIContextualAction, sourceView: UIView, completion: @escaping (Bool) -> Void) in
            self.submitPressed(postIndex: indexPath)
            
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
            if let pvc = unwindSegue.source as? PostViewController, let post = pvc.post {
                if let selectedIndexPath = tableView.indexPathForSelectedRow { // user edited a post
                    editPost(index: selectedIndexPath, post: post)
                } else { // user added a new post
                    addNewPost(post)
                }
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
