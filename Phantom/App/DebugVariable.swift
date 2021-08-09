//
//  DebugVariable.swift
//  Phantom
//
//  Created by River on 2021/05/11.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

// todo: retry after a few unsuccessful non-direct imgur uploads should be direct imgur upload
// todo: give all Main.storyboard views better names (like in welcome screen) [ez]
// todo: viewWillAppear to all view controllers? I think I'm underutilizing it (only in WelcomeViewController)
// todo: disable landscape interface orientation [ez]
// todo: adapt interface for landscape
// todo: add mini tutorial after adding first post ("swipe right to submit post, swipe left to delete")
// todo: fix compiler warnings
// todo: fix storyboard scene warnings
// todo: renotify about posts if user grants notification permissions in settings
// todo: indicator that there are no posts that prompts you to make one
// todo: "resubmit" setting?
// todo: app badge that counts overdue posts is possible (not just "1"). but should that be even implemented?

struct DebugVariable {
    private static let phoneDeploy = false
    
    // Debug ---------------------------------------------
    
    private static let simulateMiddlewareDebug = true
    private static let simulateRedditDebug = true
    private static let disableRetryDebug = true
    private static let directImgurUploadDebug = false
    private static let simulateErrorDebug = false
    private static let instantNotificationsDebug = false
    
    // Phone ---------------------------------------------
    
    private static let simulateMiddlewarePhone = false
    private static let simulateRedditPhone = false
    private static let disableRetryPhone = false
    private static let directImgurUploadPhone = true
    private static let simulateErrorPhone = false
    private static let instantNotificationsPhone = false
    
    // Calculated ----------------------------------------
    
    static let simulateMiddleware = phoneDeploy ? simulateMiddlewarePhone : simulateMiddlewareDebug
    static let simulateReddit = phoneDeploy ? simulateRedditPhone : simulateRedditDebug
    static let disableRetry = phoneDeploy ? disableRetryPhone : disableRetryDebug
    static let directImgurUpload = phoneDeploy ? directImgurUploadPhone : directImgurUploadDebug
    static let simulateError = phoneDeploy ? simulateErrorPhone : simulateErrorDebug
    static let instantNotifications = phoneDeploy ? instantNotificationsPhone : instantNotificationsDebug
    
    // Database wipe -------------------------------------
    
    static let wipeDatabase = false
    static let wipeAuth = false
    static let wipePosts = false
}
