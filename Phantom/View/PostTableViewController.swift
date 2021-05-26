//
//  PostTableViewController.swift
//  Phantom
//
//  Created by Rivershy on 2020/09/04.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import UIKit

class PostTableViewController: UITableViewController, PostTableViewDelegate, SlideUpMenuDelegate {
    // MARK: - Nested entities
    
    enum Segue: String {
        case showIntroduction, menuRedditLogin, menuImgurLogin, menuBulkAdd, addPost, editPost
    }
    
    // MARK: - Constants
    
    private static let TEXT_INDICATOR_SUBMITTING = "Submitting..."
    private static let TEXT_INDICATOR_DONE = "Done!"
    
    private static let COLOR_INDICATOR_SUBMITTING = UIColor.systemBlue
    private static let COLOR_INDICATOR_DONE = UIColor.systemGreen
    
    private static let DURATION_INDICATOR_DONE = 1.5
    
    // MARK: - Properties
    
    private var presenter = PostTablePresenter()
    private let slideUpMenu = SlideUpMenu()
    
    // MARK: - Views
    
    @IBOutlet private weak var submissionIndicatorView: UIView!
    @IBOutlet private weak var submissionIndicatorLabel: UILabel!
    @IBOutlet private weak var submissionIndicatorActivity: UIActivityIndicatorView! // loading icon thing
    
    @IBOutlet weak var imgurButton: UIBarButtonItem!
    @IBOutlet weak var moreButtton: UIBarButtonItem!
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        subscribeToNotifications()
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
    
    func segueToRedditLogin() {
        segueTo(.menuRedditLogin)
    }
    
    func segueToImgurLogin() {
        segueTo(.menuImgurLogin)
    }
    
    func segueToBulkAdd() {
        segueTo(.menuBulkAdd)
    }
    
    private func segueTo(_ segue: Segue) {
        performSegue(withIdentifier: segue.rawValue, sender: nil)
    }
    
    func loginReddit(with reddit: Reddit) {
        presenter.redditLoggedIn(reddit)
        
        // todo: remove the previous view controllers from the navigation stack
    }
    
    func loginImgur(with imgur: Imgur) {
        presenter.imgurLoggedIn(imgur)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch Segue(rawValue: segue.identifier ?? "") {
        case .editPost:
            let dest = segue.destination as! PostViewController
            let selectedCell = sender as! PostCell
            let indexPath = tableView.indexPath(for: selectedCell)!
            let selectedPost = presenter.getPost(at: indexPath.row)
            dest.supplyPost(selectedPost)
            
        case .showIntroduction,
             .addPost,
             .menuRedditLogin,
             .menuImgurLogin,
             .menuBulkAdd:
            break
            
        default:
            fatalError()
        }
    }
    
    @IBAction func unwindToPostList(unwindSegue: UIStoryboardSegue) {
        switch unwindSegue.identifier ?? "" {
        case PostViewController.Segue.backSavePost.rawValue:
            if let pvc = unwindSegue.source as? PostViewController {
                let (post, isNewPost) = pvc.getResultingPost()
                
                if isNewPost {
                    presenter.newPostAdded(post)
                } else { // user edited a post
                    presenter.postEdited(post)
                }
            } else {
                fatalError()
            }
        
        case BulkAddViewController.Segue.backBulkAdd.rawValue:
            if let bavc = unwindSegue.source as? BulkAddViewController {
                if let bulkPosts = bavc.getResultingPosts() {
                    presenter.newPostsAdded(bulkPosts)
                }
            } else {
                fatalError()
            }
            
        case LoginViewController.Segue.backLoginToList.rawValue:
            break
            
        case ImgurViewController.Segue.backImgurToList.rawValue:
            break
            
        default:
            fatalError()
        }
    }
    
    // MARK: - Submission indicator
    
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
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presenter.getPostCount()
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
    
    func updateSlideUpMenu(redditName: String?, redditLoggedIn: Bool) {
        slideUpMenu.redditName = redditName
        slideUpMenu.redditLoggedIn = redditLoggedIn
        slideUpMenu.updateRedditViews()
    }
    
    func updateSlideUpMenu(imgurName: String?, imgurLoggedIn: Bool) {
        slideUpMenu.imgurName = imgurName
        slideUpMenu.imgurLoggedIn = imgurLoggedIn
        slideUpMenu.updateImgurViews()
    }
    
    func updateSlideUpMenu(wallpaperMode: Bool, useWallhaven: Bool) {
        slideUpMenu.wallpaperMode = wallpaperMode
        slideUpMenu.useWallhaven = useWallhaven
        slideUpMenu.updateSwitchViews()
    }
    
    func showAlert(title: String, message: String) {
        displayAlert(title: title, message: message)
    }
    
    // MARK: - Emitter methods
    
    func redditButtonPressed() {
        presenter.redditButtonPressed()
    }
    
    func imgurButtonPressed() {
        presenter.imgurButtonPressed()
    }
    
    func bulkAddButtonPressed() {
        presenter.bulkAddButtonPressed()
    }
    
    func wallpaperModeSwitched(on: Bool) {
        presenter.wallpaperModeSwitched(on: on)
    }
    
    func useWallhavenSwitched(on: Bool) {
        presenter.useWallhavenSwitched(on: on)
    }
    
    @IBAction func moreButtonPressed(_ sender: Any) {
        presenter.moreButtonPressed()
    }
    
    // MARK: - Helper methods
    
    private static func getWindow() -> UIWindow? {
        return UIApplication.shared.windows.first(where: { $0.isKeyWindow })
    }
    
    // MARK: - Lifecycle notifications
    
    private func subscribeToNotifications() {
        let center = NotificationCenter.default
        
        center.addObserver(self, selector: #selector(sceneWillEnterForeground), name: UIScene.willEnterForegroundNotification, object: nil)
        center.addObserver(self, selector: #selector(sceneDidActivate), name: UIScene.didActivateNotification, object: nil)
        center.addObserver(self, selector: #selector(sceneWillDeactivate), name: UIScene.willDeactivateNotification, object: nil)
        center.addObserver(self, selector: #selector(sceneDidEnterBackground), name: UIScene.didEnterBackgroundNotification, object: nil)
        
        center.addObserver(self, selector: #selector(zombieWokeUp), name: PostNotifier.NOTIFICATION_ZOMBIE_WOKE_UP, object: nil)
        center.addObserver(self, selector: #selector(zombieSubmitted), name: PostNotifier.NOTIFICATION_ZOMBIE_SUBMITTED, object: nil)
        center.addObserver(self, selector: #selector(zombieFailed), name: PostNotifier.NOTIFICATION_ZOMBIE_FAILED, object: nil)
    }
    
    private func unsubscribeFromNotifications() {
        let center = NotificationCenter.default
        
        center.removeObserver(self, name: UIScene.willEnterForegroundNotification, object: nil)
        center.removeObserver(self, name: UIScene.didActivateNotification, object: nil)
        center.removeObserver(self, name: UIScene.willDeactivateNotification, object: nil)
        center.removeObserver(self, name: UIScene.didEnterBackgroundNotification, object: nil)
        
        center.removeObserver(self, name: PostNotifier.NOTIFICATION_ZOMBIE_WOKE_UP, object: nil)
        center.removeObserver(self, name: PostNotifier.NOTIFICATION_ZOMBIE_SUBMITTED, object: nil)
        center.removeObserver(self, name: PostNotifier.NOTIFICATION_ZOMBIE_FAILED, object: nil)
    }
    
    deinit {
        unsubscribeFromNotifications()
    }
}
