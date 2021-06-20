//
//  DebugVariable.swift
//  Phantom
//
//  Created by River on 2021/05/11.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

// todo: retry after a few unsuccessful non-direct imgur uploads should be direct imgur upload

struct DebugVariable {
    private static let phoneDeploy = false
    
    // Debug ---------------------------------------------
    
    private static let simulateMiddlewareDebug = false
    private static let simulateRedditDebug = true
    private static let disableRetryDebug = true
    private static let directImgurUploadDebug = false
    private static let simulateErrorDebug = false
    
    // Phone ---------------------------------------------
    
    private static let simulateMiddlewarePhone = false
    private static let simulateRedditPhone = false
    private static let disableRetryPhone = false
    private static let directImgurUploadPhone = true
    private static let simulateErrorPhone = false
    
    // Calculated ----------------------------------------
    
    static let simulateMiddleware = phoneDeploy ? simulateMiddlewarePhone : simulateMiddlewareDebug
    static let simulateReddit = phoneDeploy ? simulateRedditPhone : simulateRedditDebug
    static let disableRetry = phoneDeploy ? disableRetryPhone : disableRetryDebug
    static let directImgurUpload = phoneDeploy ? directImgurUploadPhone : directImgurUploadDebug
    static let simulateError = phoneDeploy ? simulateErrorPhone : simulateErrorDebug
    
    // Database wipe -------------------------------------
    
    static let wipeDatabase = false
    static let wipeAuth = false
    static let wipePosts = false
}
