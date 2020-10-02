//
//  PostTableViewController.swift
//  Phantom
//
//  Created by Rivershy on 2020/09/04.
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
    let database: Database = .instance
    let submitter: PostSubmitter = .instance
    let zombie: ZombieSubmitter = .instance
    
    // todo: let user know the zombie is submitting?
    // todo: disable zombie submission during controller submission?
    var disableSubmissionBecauseController = false // needed to prevent multiple post submission
    var disabledPostIdBecauseController: UUID? // needed to disable editing segues for submitting post
    
    var disableSubmissionBecauseZombie = false // needed to prevent submission when zombie is awake/submitting
    var disabledPostIdBecauseZombie: UUID? // needed to disable editing for the post that zombie is submitting
    
    private var disableSubmission: Bool {
        return disableSubmissionBecauseController || disableSubmissionBecauseZombie
    }
    
    private var disabledPostIds: [UUID] {
        var ids = [UUID]()
        
        if let becauseControllerId = disabledPostIdBecauseController {
            ids.append(becauseControllerId)
        }
        
        if let becauseZombieId = disabledPostIdBecauseZombie {
            ids.append(becauseZombieId)
        }
        
        return ids
    }
    
    var postIdsToBeDeleted: [UUID] = []
    
    var sceneActivated = true
    var sceneInForeground = true
    
    var posts: [Post] = []
    
    @IBOutlet weak var submissionIndicatorView: UIView!
    @IBOutlet weak var submissionIndicatorLabel: UILabel!
    @IBOutlet weak var submissionIndicatorActivity: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        subscribeToNotifications()
        addSubmissionIndicatorView()
        setupPostSubmitter()
        loadPostsFromDatabase()
        
        if zombie.awake.value {
            // we are doing this only because of the following scenario:
            // - the app is not open (it's dead)
            // - user gets a post notification
            // - user submits via the notification
            // - user opens the app while the zombie is still submitting
            // but the app couldn't have gotten the notification that
            // the zombie has awoken because the app was dead
            // so we check if the zombie is awake here
            // and disable submission/postId according to zombie
            
            disableSubmissionBecauseZombie = true
            
            let zombieId = zombie.submissionId.value
            assert(zombieId != nil)
            disabledPostIdBecauseZombie = zombieId
        }
    }
    
    deinit {
        unsubscribeFromNotifications()
    }
    
    @objc func sceneWillEnterForeground() {
        Log.p("scene will enter foreground")
        sceneInForeground = true
    }
    
    @objc func sceneDidActivate() {
        Log.p("scene did activate")
        sceneActivated = true
        
        if !postIdsToBeDeleted.isEmpty { // todo: move this to sceneWillEnterForeground!?
            deletePosts(ids: postIdsToBeDeleted, withAnimation: .right, cancelNotify: false)
            postIdsToBeDeleted.removeAll()
        }
    }
    
    @objc func sceneWillDeactivate() {
        Log.p("scene will deactivate")
        sceneActivated = false
        
        saveData()
    }
    
    @objc func sceneDidEnterBackground() {
        Log.p("scene did enter background")
        sceneInForeground = false
        
        updateAppBadge()
    }
    
    @objc func zombieWokeUp(notification: Notification) {
        Log.p("zombie woke up")
        
        // todo: decide if I use post id from notification or from zombie.submissionId
        let submissionId = PostNotifier.getPostId(notification: notification)
        
        disableSubmissionBecauseZombie = true
        disabledPostIdBecauseZombie = submissionId
    }
    
    @objc func zombieSubmitted(notification: Notification) {
        Log.p("zombie submitted")
        
        let submittedPostId = PostNotifier.getPostId(notification: notification)
        
        if sceneActivated { // we're reloading only when app is currently visible
            DispatchQueue.main.async { [unowned self] in // todo: use "unowned self" capture list wherever needed
                self.deletePosts(ids: [submittedPostId], withAnimation: .right, cancelNotify: false)
            }
        } else { // defer deletion for when app is activated
            postIdsToBeDeleted.append(submittedPostId)
        }
        
        disableSubmissionBecauseZombie = false
        disabledPostIdBecauseZombie = nil
    }
    
    @objc func zombieFailed(notification: Notification) {
        Log.p("zombie failed")
        
        disableSubmissionBecauseZombie = false
        disabledPostIdBecauseZombie = nil
    }
    
    func updateAppBadge() {
        PostNotifier.updateAppBadge(posts: posts)
    }
    
    func loginReddit(with reddit: Reddit) {
        assert(submitter.reddit.value == nil)
        
        submitter.reddit.mutate { $0 = reddit }
        Log.p("i logged in reddit")
        
        // todo: remove the previous view controllers from the navigation stack
        
        redditLoggedIn = true
    }
    
    func setupPostSubmitter() {
        if submitter.reddit.value == nil {
            if let redditAuth = database.redditAuth {
                let reddit = Reddit(auth: redditAuth)
                
                if submitter.reddit.value == nil { // this is almost certainly true but you never know
                    submitter.reddit.mutate { $0 = reddit }
                }
                
                redditLoggedIn = true
            }
        } else {
            redditLoggedIn = true
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
    
    func saveData() {
        savePosts()
        saveRedditAuth()
        Log.p("saved data")
    }
    
    func saveRedditAuth() {
        if let redditAuth = submitter.reddit.value?.auth {
            database.redditAuth = redditAuth
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
        Log.p("user added new post")
        PostNotifier.notifyUser(about: post)
        
        posts.append(post)
        sortPosts()
        
        let row = posts.firstIndex(of: post)!
        let newIndexPath = IndexPath(row: row, section: 0)
        
        tableView.insertRows(at: [newIndexPath], with: animation)
    }
    
    // todo: do not update table view when user is looking at another view controller (shows warnings in console)
    
    func editPost(post: Post, with animation: UITableView.RowAnimation = .none) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            Log.p("user edited a post")
            PostNotifier.notifyUser(about: post)
            
            posts[index] = post
            sortPosts()
            
            tableView.reloadSections([0], with: animation)
        } else {
            // this situation can happen when user submits a post
            // from notification banner while editing the same post
            // in that case we just discard it since it has already been posted
            
            Log.p("edited post discarded because already posted")
        }
    }
    
    func deletePosts(ids postIds: [UUID], withAnimation animation: UITableView.RowAnimation = .none, cancelNotify: Bool = true) {
        let indicesToDelete = posts.indices.filter { postIds.contains(posts[$0].id) }
        assert(!indicesToDelete.isEmpty)
        
        for index in indicesToDelete {
            let deletedPost = posts.remove(at: index)
            if cancelNotify {
                PostNotifier.cancel(for: deletedPost)
            }
        }
        
        let indexPaths = indicesToDelete.map { IndexPath(row: $0, section: 0) }
        tableView.deleteRows(at: indexPaths, with: animation)
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
            let postId = posts[indexPath.row].id // todo: make delete post by indexPath just for this case?
            deletePosts(ids: [postId], withAnimation: .top, cancelNotify: true)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let disabled = disabledPostIds
        guard !disabled.isEmpty else { return true }
        
        let postId = posts[indexPath.row].id
        return !disabled.contains(postId)
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let disabled = disabledPostIds
        guard !disabled.isEmpty else { return indexPath }
        
        let postId = posts[indexPath.row].id
        return disabled.contains(postId) ? nil : indexPath
    }
    
    func submitPressed(postIndex: IndexPath) {
        disableSubmissionBecauseController = true
        
        let post = posts[postIndex.row]
        PostNotifier.cancel(for: post)
        
        disabledPostIdBecauseController = post.id // make the post uneditable
        setSubmissionIndicator(start: true) // let the user know
        
        submitter.submitPost(post) { url in
            Log.p("url: \(String(describing: url))")
            
            DispatchQueue.main.async {
                let success = url != nil
                if success {
                    self.deletePosts(ids: [post.id], withAnimation: .right, cancelNotify: false) // because already cancelled
                } else {
                    PostNotifier.notifyUser(about: post)
                    // todo: notify user it's gone wrong
                }
                
                self.disabledPostIdBecauseController = nil // make editable
                self.setSubmissionIndicator(start: false) {
                    // when the indicator disappears:
                    self.disableSubmissionBecauseController = false
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
            Log.p("add post segue")
            
        case PostTableViewController.SEGUE_EDIT_POST:
            let dest = segue.destination as! PostViewController
            let selectedCell = sender as! PostCell
            let indexPath = tableView.indexPath(for: selectedCell)!
            let selectedPost = posts[indexPath.row]
            dest.post = selectedPost
            Log.p("edit post segue")
            
        case PostTableViewController.SEGUE_SHOW_INTRODUCTION:
            Log.p("introduction segue")
            
        default:
            fatalError()
        }
    }
    
    @IBAction func unwindToPostList(unwindSegue: UIStoryboardSegue) {
        switch unwindSegue.identifier ?? "" {
        case PostViewController.SEGUE_BACK_POST_TO_LIST:
            if let pvc = unwindSegue.source as? PostViewController, let post = pvc.post {
                if pvc.newPost {
                    addNewPost(post)
                } else { // user edited a post
                    editPost(post: post, with: .automatic)
                }
            } else {
                fatalError()
            }
            
        case LoginViewController.SEGUE_BACK_LOGIN_TO_LIST:
            break
            
        default:
            fatalError()
        }
    }
    
    func subscribeToNotifications() {
        let center = NotificationCenter.default
        
        center.addObserver(self, selector: #selector(sceneWillEnterForeground), name: UIScene.willEnterForegroundNotification, object: nil)
        center.addObserver(self, selector: #selector(sceneDidActivate), name: UIScene.didActivateNotification, object: nil)
        center.addObserver(self, selector: #selector(sceneWillDeactivate), name: UIScene.willDeactivateNotification, object: nil)
        center.addObserver(self, selector: #selector(sceneDidEnterBackground), name: UIScene.didEnterBackgroundNotification, object: nil)
        
        center.addObserver(self, selector: #selector(zombieWokeUp), name: PostNotifier.NOTIFICATION_ZOMBIE_WOKE_UP, object: nil)
        center.addObserver(self, selector: #selector(zombieSubmitted), name: PostNotifier.NOTIFICATION_ZOMBIE_SUBMITTED, object: nil)
        center.addObserver(self, selector: #selector(zombieFailed), name: PostNotifier.NOTIFICATION_ZOMBIE_FAILED, object: nil)
    }
    
    func unsubscribeFromNotifications() {
        let center = NotificationCenter.default
        
        center.removeObserver(self, name: UIScene.willEnterForegroundNotification, object: nil)
        center.removeObserver(self, name: UIScene.didActivateNotification, object: nil)
        center.removeObserver(self, name: UIScene.willDeactivateNotification, object: nil)
        center.removeObserver(self, name: UIScene.didEnterBackgroundNotification, object: nil)
        
        center.removeObserver(self, name: PostNotifier.NOTIFICATION_ZOMBIE_WOKE_UP, object: nil)
        center.removeObserver(self, name: PostNotifier.NOTIFICATION_ZOMBIE_SUBMITTED, object: nil)
        center.removeObserver(self, name: PostNotifier.NOTIFICATION_ZOMBIE_FAILED, object: nil)
    }
}
