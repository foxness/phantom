//
//  PostTableViewController.swift
//  Phantom
//
//  Created by Rivershy on 2020/09/04.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import UIKit

class PostTableViewController: UITableViewController, PostTableViewDelegate {
    static let SEGUE_SHOW_INTRODUCTION = "showIntroduction"
    static let SEGUE_ADD_POST = "addPost"
    static let SEGUE_EDIT_POST = "editPost"
    
    static let TEXT_INDICATOR_SUBMITTING = "Submitting..."
    static let TEXT_INDICATOR_DONE = "Done!"
    
    static let COLOR_INDICATOR_SUBMITTING = UIColor.systemBlue
    static let COLOR_INDICATOR_DONE = UIColor.systemGreen
    
    static let DURATION_INDICATOR_DONE = 1.5
    
    private var presenter = PostTablePresenter()
    
    @IBOutlet weak var submissionIndicatorView: UIView!
    @IBOutlet weak var submissionIndicatorLabel: UILabel!
    @IBOutlet weak var submissionIndicatorActivity: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        subscribeToNotifications()
        addSubmissionIndicatorView()
        
        presenter.attachView(self)
        presenter.viewDidLoad()
    }
    
    deinit {
        unsubscribeFromNotifications()
    }
    
    @objc func sceneWillEnterForeground() {
        presenter.sceneWillEnterForeground()
    }
    
    @objc func sceneDidActivate() {
        presenter.sceneDidActivate()
    }
    
    @objc func sceneWillDeactivate() {
        presenter.sceneWillDeactivate()
    }
    
    @objc func sceneDidEnterBackground() {
        presenter.sceneDidEnterBackground()
    }
    
    @objc func zombieWokeUp(notification: Notification) {
        presenter.zombieWokeUp(notification: notification)
    }
    
    @objc func zombieSubmitted(notification: Notification) {
        presenter.zombieSubmitted(notification: notification)
    }
    
    @objc func zombieFailed(notification: Notification) {
        presenter.zombieFailed(notification: notification)
    }
    
    func loginReddit(with reddit: Reddit) {
        presenter.redditLoggedIn(reddit)
        
        // todo: remove the previous view controllers from the navigation stack
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
        
        presenter.viewDidAppear()
    }
    
    func segueToIntroduction() {
        performSegue(withIdentifier: PostTableViewController.SEGUE_SHOW_INTRODUCTION, sender: nil)
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
    
    func insertRows(at indices: [Int], with animation: ListAnimation) {
        let indexPaths = PostTableViewController.indicesToIndexPaths(indices)
        let rowAnimation = PostTableViewController.listAnimationToRow(animation)
        tableView.insertRows(at: indexPaths, with: rowAnimation)
    }
    
    private static func listAnimationToRow(_ listAnimation: ListAnimation) -> UITableView.RowAnimation {
        switch listAnimation {
        case .none: return .none
        case .top: return .top
        case .right: return .right
        case .automatic: return .automatic
        }
    }
    
    private static func indicesToIndexPaths(_ indices: [Int]) -> [IndexPath] {
        return indices.map { IndexPath(row: $0, section: 0) }
    }
    
    func reloadSection(with animation: ListAnimation) {
        let sections: IndexSet = [0]
        let rowAnimation = PostTableViewController.listAnimationToRow(animation)
        tableView.reloadSections(sections, with: rowAnimation)
    }
    
    func deleteRows(at indices: [Int], with animation: ListAnimation) {
        let indexPaths = PostTableViewController.indicesToIndexPaths(indices)
        let rowAnimation = PostTableViewController.listAnimationToRow(animation)
        tableView.deleteRows(at: indexPaths, with: rowAnimation)
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presenter.getPostCount()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PostCell.IDENTIFIER, for: indexPath) as! PostCell
        let post = presenter.getPost(at: indexPath.row)
        
        cell.set(post: post)
        return cell
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            presenter.postDeleted(at: indexPath.row)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return presenter.canEditPost(at: indexPath.row)
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return presenter.canEditPost(at: indexPath.row) ? indexPath : nil
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !presenter.submissionDisabled else { return UISwipeActionsConfiguration() } // this prevents multiple post submission
        
        let style = UIContextualAction.Style.normal
        let title = "Submit"
        let bgColor = UIColor.systemIndigo
        
        let handler = { (action: UIContextualAction, sourceView: UIView, completion: @escaping (Bool) -> Void) in
            self.presenter.submitPressed(postIndex: indexPath.row)
            
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
            let selectedPost = presenter.getPost(at: indexPath.row)
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
                    presenter.newPostAdded(post)
                } else { // user edited a post
                    presenter.postEdited(post)
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
