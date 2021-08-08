//
//  PostTablePresenter.swift
//  Phantom
//
//  Created by Rivershy on 2020/10/02.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation

// todo: update app icon badge when it actually should change instead of on going in bg
// todo: save posts only when they change
// todo: save reddit and imgur only when they change (after submit & on receive new)
// todo: add graceful asking for notification permissions
// todo: add nice introduction

// todo: !!! add submitting from user notification even if app was dead while notification action pressed
// todo: handle cases where there's no reddit and submit is still requested

class PostTablePresenter {
    // MARK: - Properties
    
    private weak var viewDelegate: PostTableViewDelegate?
    
    private let database: Database = .instance // todo: make them services? implement dip
    private let thumbnailResolver: ThumbnailResolver = .instance
    
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
    
    private var disableSubmissionBecauseNoReddit = false // no reddit = signed out
    
    private var sceneActivated = true // todo: move back to view controller?
    private var sceneInForeground = true // todo: remove?
    
    private var postIdsToBeDeleted: [UUID] = []
    private var postIdToBeSubmitted: UUID?
    private var postsToBeNotifiedAbout: [Post] = []
    
    private var posts: [Post] = []
    
    // MARK: - Computed properties
    
    var submissionDisabled: Bool {
        return disableSubmissionBecauseMain || disableSubmissionBecauseZombie || disableSubmissionBecauseNoReddit
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
    
    // MARK: - Delegate methods
    
    func attachView(_ viewDelegate: PostTableViewDelegate) {
        self.viewDelegate = viewDelegate
    }
    
    func detachView() {
        viewDelegate = nil
    }
    
    // MARK: - Receiver methods
    
    func redditSignedInFromIntroduction(_ reddit: Reddit) {
        submitter.reddit.mutate { $0 = reddit }
        
        database.introductionShown = true // todo: move this somewhere else?
        
        updateSubmitButton()
        saveRedditAuth() // todo: save specific data (imgur, posts etc) only when it changes
    }
    
    func submitRequestedFromUserNotification(postId: UUID) {
        // requestedFromDeadApp == true means that the notification action was pressed while the
        // app was dead and we need to wait for it to load and attach the view delegate first to submit
        let requestedFromDeadApp = viewDelegate == nil
        
        if requestedFromDeadApp {
            postIdToBeSubmitted = postId
        } else {
            submitFromUserNotification(postId: postId)
        }
    }
    
    func submitPressed(postIndex: Int) {
        let post = posts[postIndex]
        submitPost(post)
    }
    
    func bulkAddButtonPressed() {
        viewDelegate?.segueToBulkAdd()
    }
    
    func settingsButtonPressed() {
        viewDelegate?.segueToSettings()
    }
    
    func moreButtonPressed() {
        viewDelegate?.showSlideUpMenu()
    }
    
    func redditAccountChanged(_ newReddit: Reddit?) { // means account changed in settings
        submitter.reddit.mutate { $0 = newReddit }
        updateSubmitButton()
    }
    
    func imgurAccountChanged(_ newImgur: Imgur?) { // means account changed in settings
        submitter.imgur.mutate { $0 = newImgur }
    }
    
    func bulkPostsAdded(_ bulkPosts: [BulkPost]) {
        let subreddit = database.bulkAddSubreddit
        let timeOfDay = database.bulkAddTime
        
        let scheduler = PostScheduler(timeOfDay: timeOfDay)
        
        var lastDate = posts.last?.date
        
        var toBeNotifiedAbout = [Post]()
        for bulkPost in bulkPosts {
            let title = bulkPost.title
            let url = bulkPost.url
            
            let date = scheduler.getNextDate(previous: lastDate)
            lastDate = date
            
            let newPost = Post.Link(title: title, subreddit: subreddit, date: date, url: url)
            
            toBeNotifiedAbout.append(newPost)
            posts.append(newPost)
        }
        
        sortPosts()
        
        viewDelegate?.reloadPostRows(with: .right)
        updateAppBadge()
        
        if database.askedForNotificationPermissions {
            toBeNotifiedAbout.forEach {
                PostNotifier.notifyUser(about: $0)
            }
        } else {
            postsToBeNotifiedAbout.append(contentsOf: toBeNotifiedAbout)
        }
    }
    
    func postSavedUnwindCompleted() { // this always happens after newPostAdded(_ post:)
        askForNotificationPermissionsIfNeeded()
    }
    
    func bulkAddedUnwindCompleted() { // this always happens after bulkPostsAdded(_ bulkPosts:)
        askForNotificationPermissionsIfNeeded()
    }
    
    // MARK: - View lifecycle methods
    
    func viewDidLoad() {
        loadPostsFromDatabase()
        loadThumbnailResolverCache()
        
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
        showIntroductionIfNeeded()
        setupPostSubmitter()
        updateSubmitButton()
        submitPostIfNeeded()
        
//        viewDelegate?.showPostSwipeHint()
    }
    
    // MARK: - Scene lifecycle methods
    
    func sceneWillEnterForeground() {
        sceneInForeground = true
    }
    
    func sceneDidActivate() {
        sceneActivated = true
        
        if !postIdsToBeDeleted.isEmpty { // todo: move this to sceneWillEnterForeground!?
            deletePosts(ids: postIdsToBeDeleted, withAnimation: .right, cancelNotify: false)
            postIdsToBeDeleted.removeAll()
        }
    }
    
    func sceneWillDeactivate() {
        sceneActivated = false
        
        saveData()
    }
    
    func sceneDidEnterBackground() {
        sceneInForeground = false
        
        // this is here in case user disabled notifications (so they can't update badge)
        // and the post became overdue while the user was using the app
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
        
        posts.append(post)
        sortPosts()
        
        let index = posts.firstIndex(of: post)!
        viewDelegate?.insertPostRows(at: [index], with: .top)
        updateAppBadge()
        
        if database.askedForNotificationPermissions {
            PostNotifier.notifyUser(about: post)
        } else {
            postsToBeNotifiedAbout.append(post)
        }
    }
    
    // todo: do not update table view when user is looking at another view controller (shows warnings in console)
    func postEdited(_ post: Post) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            Log.p("user edited a post")
            
            PostNotifier.notifyUser(about: post)
            
            let uneditedPost = posts[index]
            if uneditedPost.url != post.url, let uneditedPostUrl = uneditedPost.url {
                Log.p("removed cached url", uneditedPostUrl)
                thumbnailResolver.removeCached(url: uneditedPostUrl)
            }
            
            posts[index] = post
            sortPosts()
            
            viewDelegate?.reloadPostRows(with: .automatic)
            updateAppBadge()
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
    
    // MARK: - Database methods
    
    private func loadPostsFromDatabase() {
        posts = database.posts
        sortPosts()
    }
    
    func loadThumbnailResolverCache() {
        thumbnailResolver.cache = database.thumbnailResolverCache ?? [String: ThumbnailResolver.ThumbnailUrl]()
    }
    
    private func saveData() {
        savePosts()
        saveRedditAuth()
        saveImgurAuth()
        saveThumbnailResolverCache()
    }
    
    private func saveRedditAuth() {
        let redditAuth = submitter.reddit.value?.auth
        database.redditAuth = redditAuth
    }
    
    private func saveImgurAuth() {
        let imgurAuth = submitter.imgur.value?.auth
        database.imgurAuth = imgurAuth
    }
    
    private func savePosts() {
        database.posts = posts
        database.savePosts()
    }
    
    private func saveThumbnailResolverCache() {
        database.thumbnailResolverCache = thumbnailResolver.cache
    }
    
    private func sortPosts() {
        posts.sort { $0.date < $1.date }
    }
    
    // MARK: - Other methods
    
    func submitPost(_ post: Post) {
        disableSubmissionBecauseMain = true
        disabledPostIdBecauseMain = post.id // make the post uneditable
        
        PostNotifier.cancel(for: post)
        
        viewDelegate?.setSubmissionIndicator(.submitting, completion: nil) // let the user know
        
        let wallpaperMode = database.wallpaperMode
        let useWallhaven = database.useWallhaven
        let useImgur = database.useImgur
        let sendReplies = database.sendReplies
        
        let params = PostSubmitter.SubmitParams(useImgur: useImgur,
                                                wallpaperMode: wallpaperMode,
                                                useWallhaven: useWallhaven,
                                                sendReplies: sendReplies)
        
        submitter.submitPost(post, with: params) { [weak self] result in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.disabledPostIdBecauseMain = nil // make editable
                
                switch result {
                case .success(let url):
                    Log.p("reddit url", url)
                    
                    self.deletePosts(ids: [post.id], withAnimation: .right, cancelNotify: false) // because already cancelled
                    
                    self.viewDelegate?.setSubmissionIndicator(.done) {
                        // when the indicator disappears:
                        self.disableSubmissionBecauseMain = false
                    }
                case .failure(let error):
                    Log.p("got error", error)
                    
                    PostNotifier.notifyUser(about: post) // reschedule the canceled notification
                    
                    self.viewDelegate?.setSubmissionIndicator(.hidden, completion: nil)
                    self.disableSubmissionBecauseMain = false
                    
                    let title = "An error has occurred"
                    let message = "\(error.localizedDescription)"
                    self.viewDelegate?.showAlert(title: title, message: message) // todo: replace with showErrorAlert(error:) ?
                }
            }
        }
    }
    
    private func deletePosts(ids postIds: [UUID], withAnimation animation: ListAnimation = .none, cancelNotify: Bool = true) {
        let indicesToDelete = posts.indices.filter { postIds.contains(posts[$0].id) }
        assert(!indicesToDelete.isEmpty)
        
        if cancelNotify {
            indicesToDelete.forEach { PostNotifier.cancel(for: posts[$0]) }
        }
        
        for indexToDelete in indicesToDelete {
            let postToDelete = posts[indexToDelete]
            if postToDelete.type == .link, let postUrl = postToDelete.url {
                Log.p("removed cached url after deletion", postUrl)
                thumbnailResolver.removeCached(url: postUrl)
            }
        }
        
        posts.remove(at: indicesToDelete)
        viewDelegate?.deletePostRows(at: indicesToDelete, with: animation)
        
        updateAppBadge()
    }
    
    private func updateAppBadge() {
        PostNotifier.updateAppBadge(posts: posts)
    }
    
    private func showIntroductionIfNeeded() {
        guard !database.introductionShown else { return }
        
        viewDelegate?.segueToIntroduction()
    }
    
    private func submitPostIfNeeded() {
        guard let postIdToBeSubmitted = postIdToBeSubmitted else { return }
        self.postIdToBeSubmitted = nil
        
        submitFromUserNotification(postId: postIdToBeSubmitted)
    }
    
    private func submitFromUserNotification(postId: UUID) {
        guard let post = posts.first(where: { $0.id == postId }) else {
            Log.p("post not found")
            return
        }
        
        submitPost(post)
    }
    
    private func updateSubmitButton() {
        let redditSignedIn = submitter.reddit.value?.isSignedIn ?? false
        disableSubmissionBecauseNoReddit = !redditSignedIn
    }
    
    private func setupPostSubmitter() {
        submitter.reddit.mutate { reddit in
            guard reddit == nil else { return }
            
            if let redditAuth = database.redditAuth {
                reddit = Reddit(auth: redditAuth)
            }
        }
        
        submitter.imgur.mutate { imgur in
            guard imgur == nil else { return }
            
            if let imgurAuth = database.imgurAuth {
                imgur = Imgur(auth: imgurAuth)
            }
        }
    }
    
    private func askForNotificationPermissionsIfNeeded() {
        guard !database.askedForNotificationPermissions else { return }
        database.askedForNotificationPermissions = true
        
        assert(!postsToBeNotifiedAbout.isEmpty)
        
        let multiplePosts = postsToBeNotifiedAbout.count != 1
        viewDelegate?.showNotificationPermissionAskAlert(multiplePosts: multiplePosts) { userAgreed in
            Log.p("user \(userAgreed ? "agreed" : "didn't agree")")
            
            guard userAgreed else { return }
            
            Notifications.requestPermissions { [self] granted, error in
                if !granted {
                    Log.p("permissions not granted :0")
                }
                
                if let error = error {
                    Log.p("permissions error", error)
                }
                
                postsToBeNotifiedAbout.forEach {
                    // it's perfectly safe to call this even if permissions were not granted
                    // it just won't do anything in that case
                    PostNotifier.notifyUser(about: $0)
                }
                
                postsToBeNotifiedAbout.removeAll()
                
                self.viewDelegate?.showPostSwipeHint()
            }
        }
    }
}
