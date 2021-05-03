//
//  PostTablePresenter.swift
//  Phantom
//
//  Created by Rivershy on 2020/10/02.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation

class PostTablePresenter {
    // MARK: - Properties
    
    private weak var viewDelegate: PostTableViewDelegate?
    
    private let database: Database = .instance // todo: make them services? implement dip
    private let submitter: PostSubmitter = .instance
    private let zombie: ZombieSubmitter = .instance
    
    // todo: let user know the zombie is submitting?
    // todo: disable zombie submission during controller submission?
    // main means the main portion of the app aka what you see when you open the app
    private var disableSubmissionBecauseMain = false // needed to prevent multiple post submission
    private var disabledPostIdBecauseMain: UUID? // needed to disable editing segues for submitting post
    
    // zombie means the invisible/background daemon that submits when you press submit from a notification
    private var disableSubmissionBecauseZombie = false // needed to prevent submission when zombie is awake/submitting
    private var disabledPostIdBecauseZombie: UUID? // needed to disable editing for the post that zombie is submitting
    
    private var sceneActivated = true // todo: move back to view controller?
    private var sceneInForeground = true
    
    private var postIdsToBeDeleted: [UUID] = []
    private var posts: [Post] = []
    
    // MARK: - Computed properties
    
    var submissionDisabled: Bool {
        return disableSubmissionBecauseMain || disableSubmissionBecauseZombie
    }
    
    private var disabledPostIds: [UUID] {
        var ids = [UUID]()
        
        if let becauseControllerId = disabledPostIdBecauseMain {
            ids.append(becauseControllerId)
        }
        
        if let becauseZombieId = disabledPostIdBecauseZombie {
            ids.append(becauseZombieId)
        }
        
        return ids
    }
    
    // MARK: - Public methods
    
    func attachView(_ viewDelegate: PostTableViewDelegate) {
        self.viewDelegate = viewDelegate
    }
    
    func detachView() {
        viewDelegate = nil
    }
    
    func redditLoggedIn(_ reddit: Reddit) {
        assert(submitter.reddit.value == nil)
        
        submitter.reddit.mutate { $0 = reddit }
        Log.p("I logged in reddit")
    }
    
    func imgurLoggedIn(_ imgur: Imgur) {
        assert(submitter.imgur.value == nil)
        
        submitter.imgur.mutate { $0 = imgur }
        Log.p("I logged in imgur")
        
        viewDelegate?.disableImgurLogin()
    }
    
    func submitPressed(postIndex: Int) {
        disableSubmissionBecauseMain = true
        
        let post = posts[postIndex]
        PostNotifier.cancel(for: post)
        
        disabledPostIdBecauseMain = post.id // make the post uneditable
        
        viewDelegate?.setSubmissionIndicator(start: true, onDisappear: nil) // let the user know
        
        submitter.submitPost(post) { url, error in
            // todo: handle error !!1
            
            Log.p("url: \(String(describing: url))")
            
            DispatchQueue.main.async {
                let success = url != nil
                if success {
                    self.deletePosts(ids: [post.id], withAnimation: .right, cancelNotify: false) // because already cancelled
                } else {
                    PostNotifier.notifyUser(about: post)
                    // todo: notify user it's gone wrong
                }
                
                self.disabledPostIdBecauseMain = nil // make editable
                self.viewDelegate?.setSubmissionIndicator(start: false) {
                    // when the indicator disappears:
                    self.disableSubmissionBecauseMain = false
                }
            }
        }
    }
    
    // MARK: - View lifecycle methods
    
    func viewDidLoad() {
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
    
    func viewDidAppear() {
        Notifications.requestPermissions { granted, error in
            if !granted {
                Log.p("permissions not granted :0")
            }
            
            if let error = error {
                Log.p("permissions error", error)
            }
        }
        
        setupPostSubmitter()
    }
    
    // MARK: - Scene lifecycle methods
    
    func sceneWillEnterForeground() {
        Log.p("scene will enter foreground")
        sceneInForeground = true
    }
    
    func sceneDidActivate() {
        Log.p("scene did activate")
        sceneActivated = true
        
        if !postIdsToBeDeleted.isEmpty { // todo: move this to sceneWillEnterForeground!?
            deletePosts(ids: postIdsToBeDeleted, withAnimation: .right, cancelNotify: false)
            postIdsToBeDeleted.removeAll()
        }
    }
    
    func sceneWillDeactivate() {
        Log.p("scene will deactivate")
        sceneActivated = false
        
        saveData()
    }
    
    func sceneDidEnterBackground() {
        Log.p("scene did enter background")
        sceneInForeground = false
        
        updateAppBadge()
    }
    
    // MARK: - Zombie lifecycle methods
    
    func zombieWokeUp(notification: Notification) {
        Log.p("zombie woke up")
        
        // todo: decide if I use post id from notification or from zombie.submissionId
        let submissionId = PostNotifier.getPostId(notification: notification)
        
        disableSubmissionBecauseZombie = true
        disabledPostIdBecauseZombie = submissionId
    }
    
    func zombieSubmitted(notification: Notification) {
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
    
    func zombieFailed(notification: Notification) {
        Log.p("zombie failed")
        
        disableSubmissionBecauseZombie = false
        disabledPostIdBecauseZombie = nil
    }
    
    // MARK: - Post list methods
    
    func getPost(at index: Int) -> Post { posts[index] }
    
    func getPostCount() -> Int { posts.count }
    
    func canEditPost(at index: Int) -> Bool {
        let disabled = disabledPostIds
        guard !disabled.isEmpty else { return true }
        
        let postId = posts[index].id
        return !disabled.contains(postId)
    }
    
    func newPostAdded(_ post: Post) {
        Log.p("user added new post")
        PostNotifier.notifyUser(about: post)
        
        posts.append(post)
        sortPosts()
        
        let index = posts.firstIndex(of: post)!
        viewDelegate?.insertPostRows(at: [index], with: .top)
    }
    
    // todo: do not update table view when user is looking at another view controller (shows warnings in console)
    func postEdited(_ post: Post) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            Log.p("user edited a post")
            PostNotifier.notifyUser(about: post)
            
            posts[index] = post
            sortPosts()
            
            viewDelegate?.reloadPostRows(with: .automatic)
        } else {
            // this situation can happen when user submits a post
            // from notification banner while editing the same post
            // in that case we just discard it since it has already been posted
            
            Log.p("edited post discarded because already posted")
        }
    }
    
    func postDeleted(at index: Int) {
        let id = posts[index].id
        deletePosts(ids: [id], withAnimation: .top, cancelNotify: true)
    }
    
    func newPostsAdded(_ posts: [Post]) {
        // todo: do handle this
    }
    
    // MARK: - Database methods
    
    private func loadPostsFromDatabase() {
        posts = database.posts
        sortPosts()
    }
    
    private func saveData() {
        savePosts()
        saveRedditAuth()
        saveImgurAuth()
        Log.p("saved data")
    }
    
    private func saveRedditAuth() {
        if let redditAuth = submitter.reddit.value?.auth {
            database.redditAuth = redditAuth
        }
    }
    
    private func saveImgurAuth() {
        if let imgurAuth = submitter.imgur.value?.auth {
            database.imgurAuth = imgurAuth
        }
    }
    
    private func savePosts() {
        database.posts = posts
        database.savePosts()
    }
    
    private func sortPosts() {
        posts.sort { $0.date < $1.date }
    }
    
    // MARK: - Misc methods
    
    private func deletePosts(ids postIds: [UUID], withAnimation animation: ListAnimation = .none, cancelNotify: Bool = true) {
        let indicesToDelete = posts.indices.filter { postIds.contains(posts[$0].id) }
        assert(!indicesToDelete.isEmpty)
        
        if cancelNotify {
            indicesToDelete.forEach { PostNotifier.cancel(for: posts[$0]) }
        }
        
        posts.remove(at: indicesToDelete)
        viewDelegate?.deletePostRows(at: indicesToDelete, with: animation)
    }
    
    private func updateAppBadge() {
        PostNotifier.updateAppBadge(posts: posts)
    }
    
    private func setupPostSubmitter() {
        var redditLogged = false
        var imgurLogged = false
        
        if submitter.reddit.value == nil {
            if let redditAuth = database.redditAuth {
                let reddit = Reddit(auth: redditAuth)
                
                if submitter.reddit.value == nil { // this is almost certainly true but you never know
                    submitter.reddit.mutate { $0 = reddit }
                }
                
                redditLogged = true
            }
        } else {
            redditLogged = true
        }
        
        if submitter.imgur.value == nil {
            if let imgurAuth = database.imgurAuth {
                let imgur = Imgur(auth: imgurAuth)
                
                if submitter.imgur.value == nil { // this is almost certainly true but you never know
                    submitter.imgur.mutate { $0 = imgur }
                }
                
                imgurLogged = true
            }
        } else {
            imgurLogged = true
        }
        
        if !redditLogged {
            viewDelegate?.segueToIntroduction()
        }
        
        if imgurLogged {
            viewDelegate?.disableImgurLogin()
        }
    }
}
