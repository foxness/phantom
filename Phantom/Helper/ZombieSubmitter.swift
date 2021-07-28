//
//  ZombieSubmitter.swift
//  Phantom
//
//  Created by Rivershy on 2020/09/13.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation

// todo: reverse dns names wherever possible

// zombie submitter todo:
// - create imgur instance for submitter if it's not created yet (similar to reddit ^)
// - save imgur auth after submission (similar to reddit)
// - upload image to imgur only with url and not directly in zombie because time is precious here?
// - notify user if there was an error
// - lots of refactor
// - revive by enabling submit notification action again

struct ZombieSubmitter {
    static let NOTIFICATION_WOKE_UP = Notification.Name("zombieWokeUp")
    static let NOTIFICATION_SUBMITTED = Notification.Name("zombieSubmittedFromBeyondTheGrave")
    static let NOTIFICATION_FAILED = Notification.Name("zombieFailed")
    
    private static let KEY_POST_ID = "postId"
    
    static let instance = ZombieSubmitter()
    
    private let database = Database.instance
    private let submitter = PostSubmitter.instance
    
    private(set) var awake = Atomic<Bool>(false)
    private(set) var submissionId = Atomic<UUID?>(nil)
    
    private init() { }
    
    func submitPost(id: UUID, callback: @escaping () -> Void) {
        awake.mutate { $0 = true }
        submissionId.mutate { $0 = id }
        
        ZombieSubmitter.notifyZombieWokeUp(postId: id)
        
        guard let postIndex = database.posts.firstIndex(where: { $0.id == id }) else {
            // if we get to this situation it means:
            // - the notification banner popped up
            // - the user deleted the post of the notification in app while the notification banned was still popped up
            // - the user pressed on the submit button of the notification banner while it was still popped up
            // the popped up notification banner can't be removed by removing the notification upon post deletion
            // post deletion removes the notification only in the notification center
            // so we have to account for that niche situation here
            
            Log.p("post wasnt found")
            ZombieSubmitter.notifyZombieFailed(postId: id)
            
            callback()
            awake.mutate { $0 = false }
            submissionId.mutate { $0 = nil }
            return
        }
        
        let post = database.posts[postIndex]
        let wallpaperMode = database.wallpaperMode
        let useWallhaven = database.useWallhaven
        let useImgur = database.useImgur
        
        var reddit: Reddit!
        var shouldGrabRedditFromSubmitter = true
        if submitter.reddit.value == nil {
            let redditAuth = database.redditAuth!
            reddit = Reddit(auth: redditAuth)
            
            if submitter.reddit.value == nil { // this will almost certainly be true but you never know
                submitter.reddit.mutate { $0 = reddit }
                shouldGrabRedditFromSubmitter = false
            }
        }
        
        if shouldGrabRedditFromSubmitter {
            reddit = submitter.reddit.value
            Log.p("zombie: used existing reddit")
        }
        
        let params = PostSubmitter.SubmitParams(useImgur: useImgur, wallpaperMode: wallpaperMode, useWallhaven: useWallhaven)
        
        submitter.submitPost(post, with: params) { result in
            switch result {
            case .success(let url):
                Log.p("reddit url", url)
                
                self.database.posts.remove(at: postIndex)
                self.database.savePosts()
                
                let redditAuth = reddit.auth
                self.database.redditAuth = redditAuth
                
                ZombieSubmitter.notifyZombieSubmitted(postId: id)
                
                let posts = self.database.posts
                PostNotifier.updateAppBadge(posts: posts)
            case .failure(let error):
                Log.p("got error", error)
                
                // todo: handle error !!1
                
                ZombieSubmitter.notifyZombieFailed(postId: id)
                // todo: issue submission error user notification
            }
            
            self.awake.mutate { $0 = false }
            self.submissionId.mutate { $0 = nil }
            callback()
        }
    }
    
    static func getPostId(notification: Notification) -> UUID {
        return notification.userInfo![KEY_POST_ID]! as! UUID
    }
    
    private static func notify(name: Notification.Name, postId: UUID) {
        let userInfo = [KEY_POST_ID: postId]
        NotificationCenter.default.post(name: name, object: nil, userInfo: userInfo)
    }
    
    private static func notifyZombieWokeUp(postId: UUID) {
        notify(name: NOTIFICATION_WOKE_UP, postId: postId)
    }
    
    private static func notifyZombieSubmitted(postId: UUID) {
        notify(name: NOTIFICATION_SUBMITTED, postId: postId)
    }
    
    private static func notifyZombieFailed(postId: UUID) { // todo: utilize this
        notify(name: NOTIFICATION_FAILED, postId: postId)
    }
}
