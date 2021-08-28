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
    private let thumbnailResolver: ThumbnailResolver = .instance
    
    private let submitter: PostSubmitter = .instance
    
    private var currentlySubmitting = false
    private var currentlySubmittingPostId: UUID?
    
    private var sceneActivated = true // todo: move back to view controller?
    private var sceneInForeground = true // todo: remove?
    
    private var postIdToBeSubmitted: UUID?
    private var postsToBeNotifiedAbout: [Post] = []
    
    private var posts: [Post] = []
    
    // MARK: - Computed properties
    
    var submissionDisabled: Bool {
        return currentlySubmitting
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
        saveRedditAuth()
        
        database.introductionShown = true // todo: move this somewhere else?
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
        tryToSubmitPost(post)
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
    
    func redditAccountChanged(_ newReddit: Reddit?) { // is called when the account is changed settings
        submitter.reddit.mutate { $0 = newReddit }
        saveRedditAuth()
    }
    
    func imgurAccountChanged(_ newImgur: Imgur?) { // is called when the account is changed settings
        submitter.imgur.mutate { $0 = newImgur }
        saveImgurAuth()
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
        savePosts()
        
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
        setupPostSubmitter()
    }
    
    func viewDidAppear() {
        showIntroductionIfNeeded()
        submitPostIfNeeded()
    }
    
    // MARK: - Scene lifecycle methods
    
    func sceneWillEnterForeground() {
        sceneInForeground = true
    }
    
    func sceneDidActivate() {
        sceneActivated = true
    }
    
    func sceneWillDeactivate() {
        sceneActivated = false
        
        // todo: move to viewWillDisappear() instead?
        // todo: save thumbnail cache only when it changes?
        saveThumbnailResolverCache()
    }
    
    func sceneDidEnterBackground() {
        sceneInForeground = false
        
        // this is here in case user disabled notifications (so they can't update badge)
        // and the post became overdue while the user was using the app
        updateAppBadge() // todo: move this to sceneWillDeactivate() instead?
    }
    
    // MARK: - Post list methods
    
    func getPost(at index: Int) -> Post {
        return posts[index]
    }
    
    func getPostCount() -> Int {
        return posts.count
    }
    
    func canEditPost(at index: Int) -> Bool {
        return posts[index].id != currentlySubmittingPostId
    }
    
    func newPostAdded(_ post: Post) {
        Log.p("user added new post")
        
        posts.append(post)
        sortPosts()
        
        let index = posts.firstIndex(of: post)!
        viewDelegate?.insertPostRows(at: [index], with: .top)
        updateAppBadge()
        savePosts()
        
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
            savePosts()
        } else {
            // this situation can happen when user submits a post
            // from notification banner while editing the same post
            // in that case we just discard it since it has already been posted
            
            Log.p("edited post discarded because already posted") // todo: revisit this situation and check if this happens
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
    
    private func loadThumbnailResolverCache() {
        thumbnailResolver.cache = database.thumbnailResolverCache ?? [String: ThumbnailResolver.ThumbnailUrl]()
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
    
    private func tryToSubmitPost(_ post: Post) {
        guard submitter.reddit.value?.isSignedIn == true else {
            viewDelegate?.showSignedOutRedditAlert()
            return
        }
        
        submitPost(post)
    }
    
    private func submitPost(_ post: Post) {
        currentlySubmitting = true
        currentlySubmittingPostId = post.id // make the post uneditable
        
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
                
                self.currentlySubmittingPostId = nil // make editable
                self.saveRedditAuth()
                self.saveImgurAuth()
                
                switch result {
                case .success(let url):
                    Log.p("reddit url", url)
                    
                    self.deletePosts(ids: [post.id], withAnimation: .right, cancelNotify: false) // because already cancelled
                    
                    self.viewDelegate?.setSubmissionIndicator(.done) {
                        // when the indicator disappears:
                        self.currentlySubmitting = false
                    }
                case .failure(let error):
                    Log.p("got error", error)
                    
                    PostNotifier.notifyUser(about: post) // reschedule the canceled notification
                    
                    self.viewDelegate?.setSubmissionIndicator(.hidden, completion: nil)
                    self.currentlySubmitting = false
                    
                    self.viewDelegate?.showGenericErrorAlert(errorMessage: error.localizedDescription)
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
        savePosts()
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
        guard let post = posts.first(where: { $0.id == postId }) else { // theoretically we can never get into this guard
            Log.p("post not found")
            return
        }
        
        tryToSubmitPost(post)
    }
    
    private func setupPostSubmitter() {
        submitter.reddit.mutate { reddit in
            guard reddit == nil else { return }
            
            if let redditAuth = database.redditAuth {
                let redditClientId = AppVariables.Api.redditClientId
                let redditRedirectUri = AppVariables.Api.redditRedirectUri
                
                reddit = Reddit(clientId: redditClientId,
                                redirectUri: redditRedirectUri,
                                auth: redditAuth)
            }
        }
        
        submitter.imgur.mutate { imgur in
            guard imgur == nil else { return }
            
            if let imgurAuth = database.imgurAuth {
                let imgurClientId = AppVariables.Api.imgurClientId
                let imgurClientSecret = AppVariables.Api.imgurClientSecret
                let imgurRedirectUri = AppVariables.Api.imgurRedirectUri
                
                imgur = Imgur(clientId: imgurClientId,
                              clientSecret: imgurClientSecret,
                              redirectUri: imgurRedirectUri,
                              auth: imgurAuth)
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
