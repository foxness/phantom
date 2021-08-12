//
//  PostTableViewController.swift
//  Phantom
//
//  Created by Rivershy on 2020/09/04.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import UIKit

class PostTableViewController: UITableViewController, PostTableViewDelegate, SlideUpMenuDelegate, RedditSignInReceiver, SettingsDelegate {
    // MARK: - Nested entities
    
    enum Segue: String {
        case showIntroduction = "postsShowIntroduction"
        case showSettings = "postsShowSettings"
        case showBulkAdd = "postsShowBulkAdd"
        case showAddPost = "postsShowAddPost"
        case showEditPost = "postsShowEditPost"
    }
    
    // MARK: - Constants
    
    private static let TEXT_INDICATOR_SUBMITTING = "Submitting..."
    private static let TEXT_INDICATOR_DONE = "Done!"
    private static let TEXT_TABLE_EMPTY = "No posts yet." // todo: change to "no scheduled posts yet"?
    
    private static let COLOR_INDICATOR_SUBMITTING = UIColor.systemBlue
    private static let COLOR_INDICATOR_DONE = UIColor.systemGreen
    
    private static let DURATION_INDICATOR_DONE: TimeInterval = 1.5
    private static let DURATION_SWIPE_HINT_DELAY: TimeInterval = 1
    private static let DURATION_SWIPE_HINT: TimeInterval = 0.9
    
    private static let WIDTH_SWIPE_HINT: CGFloat = 25
    private static let CORNER_RADIUS_SWIPE_HINT: CGFloat? = 9
    
    // MARK: - Properties
    
    private var presenter = PostTablePresenter()
    private let slideUpMenu = SlideUpMenu()
    
    // MARK: - Views
    
    @IBOutlet private weak var submissionIndicatorView: UIView!
    @IBOutlet private weak var submissionIndicatorLabel: UILabel!
    @IBOutlet private weak var submissionIndicatorActivity: UIActivityIndicatorView! // loading icon thing
    
    @IBOutlet weak var moreButtton: UIBarButtonItem!
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        subscribeToNotifications()
        
        styleTableView()
        addSubmissionIndicatorView()
        
        slideUpMenu.delegate = self
        slideUpMenu.setupViews(window: PostTableViewController.getWindow()!)
        
        presenter.attachView(self)
        presenter.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        presenter.viewDidAppear()
    }
    
    // MARK: - Scene lifecycle
    
    @objc private func sceneWillEnterForeground() {
        presenter.sceneWillEnterForeground()
    }
    
    @objc private func sceneDidActivate() {
        presenter.sceneDidActivate()
    }
    
    @objc private func sceneWillDeactivate() {
        presenter.sceneWillDeactivate()
    }
    
    @objc private func sceneDidEnterBackground() {
        presenter.sceneDidEnterBackground()
    }
    
    // MARK: - Zombie lifecycle
    
    @objc private func zombieWokeUp(notification: Notification) {
        presenter.zombieWokeUp(notification: notification)
    }
    
    @objc private func zombieSubmitted(notification: Notification) {
        presenter.zombieSubmitted(notification: notification)
    }
    
    @objc private func zombieFailed(notification: Notification) {
        presenter.zombieFailed(notification: notification)
    }
    
    // MARK: - Navigation
    
    func segueToIntroduction() {
        segueTo(.showIntroduction)
    }
    
    func segueToSettings() {
        segueTo(.showSettings)
    }
    
    func segueToBulkAdd() {
        segueTo(.showBulkAdd)
    }
    
    private func segueTo(_ segue: Segue) {
        performSegue(withIdentifier: segue.rawValue, sender: nil)
    }
    
    func redditSignedIn(with reddit: Reddit) {
        presenter.redditSignedInFromIntroduction(reddit)
        
        // todo: remove the previous view controllers from the navigation stack
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch Segue(rawValue: segue.identifier ?? "") {
        case .showEditPost:
            let dest = segue.destination as! PostDetailViewController
            let selectedCell = sender as! PostCell
            let indexPath = tableView.indexPath(for: selectedCell)!
            let selectedPost = presenter.getPost(at: indexPath.row)
            dest.supplyPost(selectedPost)
        
        case .showSettings:
            let dest = segue.destination as! SettingsViewController
            dest.delegate = self
            
        case .showIntroduction,
             .showAddPost,
             .showBulkAdd:
            break
            
        default:
            fatalError()
        }
    }
    
    // this is here because welcome screen has reddit login
    @IBAction func unwindRedditSignIn(unwindSegue: UIStoryboardSegue) {
        guard unwindSegue.identifier == RedditSignInViewController.Segue.unwindRedditSignedIn.rawValue else {
            fatalError("Got unexpected unwind segue")
        }
    }
    
    @IBAction func unwindPostSaved(unwindSegue: UIStoryboardSegue) {
        guard unwindSegue.identifier == PostDetailViewController.Segue.unwindPostSaved.rawValue,
              let unwindSegue = unwindSegue as? UIStoryboardSegueWithCompletion
        else {
            fatalError("Got unexpected unwind segue")
        }
        
        unwindSegue.completion = {
            self.presenter.postSavedUnwindCompleted()
        }
        
        let pvc = unwindSegue.source as! PostDetailViewController
        let (post, isNewPost) = pvc.getResultingPost()
        
        if isNewPost {
            presenter.newPostAdded(post)
        } else { // user edited a post
            presenter.postEdited(post)
        }
    }
    
    @IBAction func unwindBulkAdded(unwindSegue: UIStoryboardSegue) {
        guard unwindSegue.identifier == BulkAddViewController.Segue.unwindBulkAdded.rawValue,
              let unwindSegue = unwindSegue as? UIStoryboardSegueWithCompletion
        else {
            fatalError("Got unexpected unwind segue")
        }
        
        unwindSegue.completion = {
            self.presenter.bulkAddedUnwindCompleted()
        }
        
        let bavc = unwindSegue.source as! BulkAddViewController
        if let bulkPosts = bavc.getResultingPosts() {
            presenter.bulkPostsAdded(bulkPosts)
        }
    }
    
    // MARK: - View
    
    private func styleTableView() {
        tableView.tableFooterView = UIView() // a little hack to remove infinite divider lines below table cells
    }
    
    private func addSubmissionIndicatorView() {
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
    
    func setSubmissionIndicator(_ state: SubmissionIndicatorState, completion: (() -> Void)?) {
        switch state {
        case .submitting:
            
            submissionIndicatorActivity.isHidden = false
            submissionIndicatorLabel.text = PostTableViewController.TEXT_INDICATOR_SUBMITTING
            submissionIndicatorView.backgroundColor = PostTableViewController.COLOR_INDICATOR_SUBMITTING
            
            submissionIndicatorView.isHidden = false
            completion?()
            
        case .done:
            
            submissionIndicatorActivity.isHidden = true
            submissionIndicatorLabel.text = PostTableViewController.TEXT_INDICATOR_DONE
            submissionIndicatorView.backgroundColor = PostTableViewController.COLOR_INDICATOR_DONE
            
            let disappearTime = DispatchTime.now() + PostTableViewController.DURATION_INDICATOR_DONE
            DispatchQueue.main.asyncAfter(deadline: disappearTime) { [weak self] in
                guard let self = self else { return }
                
                self.submissionIndicatorView.isHidden = true
                completion?()
            }
            
        case .hidden:
            
            self.submissionIndicatorView.isHidden = true
            completion?()
        }
    }

    // MARK: - Table view
    
    func insertPostRows(at indices: [Int], with animation: ListAnimation) {
        let indexPaths = PostTableViewController.indicesToIndexPaths(indices)
        let rowAnimation = PostTableViewController.listAnimationToRow(animation)
        tableView.insertRows(at: indexPaths, with: rowAnimation)
    }
    
    func reloadPostRows(with animation: ListAnimation) {
        let sections: IndexSet = [0]
        let rowAnimation = PostTableViewController.listAnimationToRow(animation)
        tableView.reloadSections(sections, with: rowAnimation)
    }
    
    func deletePostRows(at indices: [Int], with animation: ListAnimation) {
        let indexPaths = PostTableViewController.indicesToIndexPaths(indices)
        let rowAnimation = PostTableViewController.listAnimationToRow(animation)
        tableView.deleteRows(at: indexPaths, with: rowAnimation)
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
    
    private func showLeadingSwipeHint(width: CGFloat = 20, duration: TimeInterval = 0.8, cornerRadius: CGFloat? = nil) {
        guard let (cell, actionColor) = tableView.getLeadingSwipeHintCell(),
              let postCell = cell as? PostCell else { return }
        
        postCell.showLeadingSwipeHint(actionColor: actionColor,
                                      width: width,
                                      duration: duration,
                                      cornerRadius: cornerRadius)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = presenter.getPostCount()
        
        if count == 0 {
            tableView.setEmptyMessage(PostTableViewController.TEXT_TABLE_EMPTY)
        } else {
            tableView.removeEmptyMessage()
        }
        
        return count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PostCell.IDENTIFIER, for: indexPath) as! PostCell
        let post = presenter.getPost(at: indexPath.row)
        
        cell.setPost(post)
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
    
    // MARK: - Receiver methods
    
    func showSlideUpMenu() {
        slideUpMenu.show()
    }
    
    func showAlert(title: String, message: String) { // todo: split into alerts for every situation intead of generic
        displayOkAlert(title: title, message: message)
    }
    
    func showNotificationPermissionAskAlert(multiplePosts: Bool, _ callback: @escaping (Bool) -> Void) {
        let title = "Notification permissions"
        let agreeTitle = "OK"
        let disagreeTitle = "Nope"
        
        let message = multiplePosts ?
            "Your permission is needed to remind you to submit your scheduled posts" :
            "Your permission is needed to remind you to submit your scheduled post at the time you picked"
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // UIColor(named: "AccentColor") is used here instead of view.tintColor because view.tintColor is grey during segues which affects this code
        alertController.view.tintColor = UIColor(named: "AccentColor") // todo: refactor all named asset inits into new struct [ez]
        
        let agreeHandler = { (action: UIAlertAction) -> Void in
            callback(true)
        }
        
        let disagreeHandler = { (action: UIAlertAction) -> Void in
            callback(false)
        }
        
        let agreeAction = UIAlertAction(title: agreeTitle, style: .default, handler: agreeHandler)
        let disagreeAction = UIAlertAction(title: disagreeTitle, style: .default, handler: disagreeHandler)
        
        alertController.addAction(disagreeAction)
        alertController.addAction(agreeAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func showPostSwipeHint() {
        // some buffer so it doesn't appear too fast after something else
        let deadline = DispatchTime.now() + PostTableViewController.DURATION_SWIPE_HINT_DELAY
        
        DispatchQueue.main.asyncAfter(deadline: deadline) {
            self.showLeadingSwipeHint(width: PostTableViewController.WIDTH_SWIPE_HINT,
                                            duration: PostTableViewController.DURATION_SWIPE_HINT,
                                            cornerRadius: PostTableViewController.CORNER_RADIUS_SWIPE_HINT)
        }
    }
    
    // MARK: - Emitter methods
    
    func bulkAddButtonPressed() {
        presenter.bulkAddButtonPressed()
    }
    
    func settingsButtonPressed() {
        presenter.settingsButtonPressed()
    }
    
    @IBAction func moreButtonPressed(_ sender: Any) {
        presenter.moreButtonPressed()
    }
    
    func redditAccountChanged(_ newReddit: Reddit?) {
        presenter.redditAccountChanged(newReddit)
    }
    
    func imgurAccountChanged(_ newImgur: Imgur?) {
        presenter.imgurAccountChanged(newImgur)
    }
    
    func submitRequestedFromUserNotification(postId: UUID) {
        presenter.submitRequestedFromUserNotification(postId: postId)
    }
    
    // MARK: - Helper methods
    
    private static func getWindow() -> UIWindow? {
        return UIApplication.shared.windows.first(where: { $0.isKeyWindow })
    }
    
    // MARK: - Internal notifications
    
    private func getNotifications() -> [(Selector, Notification.Name)] {
        var notifications = [(Selector, Notification.Name)]()
        
        notifications.append((#selector(sceneWillEnterForeground), UIScene.willEnterForegroundNotification))
        notifications.append((#selector(sceneDidActivate), UIScene.didActivateNotification))
        notifications.append((#selector(sceneWillDeactivate), UIScene.willDeactivateNotification))
        notifications.append((#selector(sceneDidEnterBackground), UIScene.didEnterBackgroundNotification))
        
        notifications.append((#selector(zombieWokeUp), PostNotifier.NOTIFICATION_ZOMBIE_WOKE_UP))
        notifications.append((#selector(zombieSubmitted), PostNotifier.NOTIFICATION_ZOMBIE_SUBMITTED))
        notifications.append((#selector(zombieFailed), PostNotifier.NOTIFICATION_ZOMBIE_FAILED))
        
        return notifications
    }
    
    private func subscribeToNotifications() {
        for notification in getNotifications() {
            NotificationCenter.default.addObserver(self, selector: notification.0, name: notification.1, object: nil)
        }
    }
    
    private func unsubscribeFromNotifications() {
        for notification in getNotifications() {
            NotificationCenter.default.removeObserver(self, name: notification.1, object: nil)
        }
    }
    
    deinit {
        unsubscribeFromNotifications()
    }
}
