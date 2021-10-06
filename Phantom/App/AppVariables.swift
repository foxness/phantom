//
//  AppVariables.swift
//  Phantom
//
//  Created by River on 2021/08/27.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

// todo:

// - post table inset to account for submission indicator height so that you can see post being submitted
// - test welcome screen button on iOS 14.0
// - add text size accessibility support
// - privacy policy on custom domain?
// - retry after a few unsuccessful non-direct imgur uploads should be direct imgur upload
// - give all Main.storyboard views better names (like in welcome screen) [ez]
// - viewWillAppear to all view controllers? I think I'm underutilizing it (only in WelcomeViewController)
// - adapt interface for landscape
// - add mini tutorial after adding first post ("swipe right to submit post, swipe left to delete")
// - fix compiler warnings
// - fix storyboard scene warnings
// - renotify about posts if user grants notification permissions in settings
// - "resubmit" setting?
// - app badge that counts overdue posts is possible (not just "1"). but should that be even implemented?
// - refactor post detail
// - add nice introduction?
// - show attempt count to user
// - let user change retry strategy
// - MARK code dividers in every source file [ez]
// - add app store link to about scene
// - get rid of "TEXT_"-like prefixes in all static variables? [ez]

struct AppVariables {
    // MARK: - Build identifiers
    
    static var configName: String { Bundle.main.configName }
    
    static var bundleIdentifier: String { Bundle.main.bundleIdentifier! }
    
    static var websiteUrl: String { Bundle.main.websiteUrl }
    static var privacyPolicyUrl: String { Bundle.main.privacyPolicyUrl }
    static var appStoreUrl: String { Bundle.main.appStoreUrl }
    
    static var version: String {
        let version = Bundle.main.releaseVersionNumber
        let build = Bundle.main.buildVersionNumber
        let config = configName
        
        let configString = config == "stable" ? "" : "[\(config)]"
        
        return "\(version) (\(build)) \(configString)".trim()
    }
    
    static var userAgent: String {
        let identifier = bundleIdentifier
        let version = Bundle.main.releaseVersionNumber
        let reddit = Developer.redditAccount
        
        return "ios:\(identifier):v\(version) (by /u/\(reddit))"
    }
    
    // MARK: - Developer variables
    
    struct Developer {
        static var name: String { Bundle.main.developerName }
        static var contactEmail: String { Bundle.main.developerContactEmail }
        static var redditAccount: String { Bundle.main.developerRedditAccount }
        static var twitterUrl: String { Bundle.main.developerTwitterUrl }
    }
    
    // MARK: - API variables
    
    struct Api {
        static var redditClientId: String { Bundle.main.redditClientId }
        static var redditRedirectUri: String { Bundle.main.redditRedirectUri }
        
        static var imgurClientId: String { Bundle.main.imgurClientId }
        static var imgurClientSecret: String { Bundle.main.imgurClientSecret }
        static var imgurRedirectUri: String { Bundle.main.imgurRedirectUri }
    }
    
    // MARK: - Debug variables
    
    struct Debug {
        static var simulateMiddleware: Bool { Bundle.main.debugSimulateMiddleware }
        static var simulateReddit: Bool { Bundle.main.debugSimulateReddit }
        static var disableRetry: Bool { Bundle.main.debugDisableRetry }
        static var disableDirectImgurUpload: Bool { Bundle.main.debugDisableDirectImgurUpload }
        static var simulateError: Bool { Bundle.main.debugSimulateError }
        static var instantNotifications: Bool { Bundle.main.debugInstantNotifications }
    }
}

extension Bundle {
    // MARK: - Default keys
    
    private static let KEY_RELEASE_VERSION_NUMBER = "CFBundleShortVersionString"
    private static let KEY_BUILD_VERSION_NUMBER = "CFBundleVersion"
    
    // MARK: - Custom keys
    
    private static let KEY_CONFIG_NAME = "PhantomConfigName"
    
    private static let KEY_DEVELOPER_NAME = "PhantomDeveloperName"
    private static let KEY_DEVELOPER_CONTACT_EMAIL = "PhantomDeveloperContactEmail"
    private static let KEY_DEVELOPER_REDDIT_ACCOUNT = "PhantomDeveloperRedditAccount"
    private static let KEY_DEVELOPER_TWITTER_URL = "PhantomDeveloperTwitterUrl"
    
    private static let KEY_WEBSITE_URL = "PhantomWebsiteUrl"
    private static let KEY_PRIVACY_POLICY_URL = "PhantomPrivacyPolicyUrl"
    private static let KEY_APP_STORE_URL = "PhantomAppStoreUrl"
    
    private static let KEY_REDDIT_CLIENT_ID = "PhantomRedditClientId"
    private static let KEY_REDDIT_REDIRECT_URI = "PhantomRedditRedirectUri"
    
    private static let KEY_IMGUR_CLIENT_ID = "PhantomImgurClientId"
    private static let KEY_IMGUR_CLIENT_SECRET = "PhantomImgurClientSecret"
    private static let KEY_IMGUR_REDIRECT_URI = "PhantomImgurRedirectUri"
    
    private static let KEY_DEBUG_SIMULATE_MIDDLEWARE = "PhantomDebugSimulateMiddleware"
    private static let KEY_DEBUG_SIMULATE_REDDIT = "PhantomDebugSimulateReddit"
    private static let KEY_DEBUG_DISABLE_RETRY = "PhantomDebugDisableRetry"
    private static let KEY_DEBUG_DISABLE_DIRECT_IMGUR_UPLOAD = "PhantomDebugDisableDirectImgurUpload"
    private static let KEY_DEBUG_SIMULATE_ERROR = "PhantomDebugSimulateError"
    private static let KEY_DEBUG_INSTANT_NOTIFICATIONS = "PhantomDebugInstantNotifications"
    
    // MARK: - Default variables
    
    fileprivate var releaseVersionNumber: String { getString(Bundle.KEY_RELEASE_VERSION_NUMBER) }
    fileprivate var buildVersionNumber: String { getString(Bundle.KEY_BUILD_VERSION_NUMBER) }
    
    // MARK: - Custom variables
    
    fileprivate var configName: String { getString(Bundle.KEY_CONFIG_NAME) }
    
    fileprivate var developerName: String { getString(Bundle.KEY_DEVELOPER_NAME) }
    fileprivate var developerContactEmail: String { getString(Bundle.KEY_DEVELOPER_CONTACT_EMAIL) }
    fileprivate var developerRedditAccount: String { getString(Bundle.KEY_DEVELOPER_REDDIT_ACCOUNT) }
    fileprivate var developerTwitterUrl: String { getString(Bundle.KEY_DEVELOPER_TWITTER_URL) }
    
    fileprivate var websiteUrl: String { getString(Bundle.KEY_WEBSITE_URL) }
    fileprivate var privacyPolicyUrl: String { getString(Bundle.KEY_PRIVACY_POLICY_URL) }
    fileprivate var appStoreUrl: String { getString(Bundle.KEY_APP_STORE_URL) }
    
    fileprivate var redditClientId: String { getString(Bundle.KEY_REDDIT_CLIENT_ID) }
    fileprivate var redditRedirectUri: String { getString(Bundle.KEY_REDDIT_REDIRECT_URI) }
    
    fileprivate var imgurClientId: String { getString(Bundle.KEY_IMGUR_CLIENT_ID) }
    fileprivate var imgurClientSecret: String { getString(Bundle.KEY_IMGUR_CLIENT_SECRET) }
    fileprivate var imgurRedirectUri: String { getString(Bundle.KEY_IMGUR_REDIRECT_URI) }
    
    fileprivate var debugSimulateMiddleware: Bool { getBool(Bundle.KEY_DEBUG_SIMULATE_MIDDLEWARE) }
    fileprivate var debugSimulateReddit: Bool { getBool(Bundle.KEY_DEBUG_SIMULATE_REDDIT) }
    fileprivate var debugDisableRetry: Bool { getBool(Bundle.KEY_DEBUG_DISABLE_RETRY) }
    fileprivate var debugDisableDirectImgurUpload: Bool { getBool(Bundle.KEY_DEBUG_DISABLE_DIRECT_IMGUR_UPLOAD) }
    fileprivate var debugSimulateError: Bool { getBool(Bundle.KEY_DEBUG_SIMULATE_ERROR) }
    fileprivate var debugInstantNotifications: Bool { getBool(Bundle.KEY_DEBUG_INSTANT_NOTIFICATIONS) }
    
    // MARK: - Helper
    
    private func getString(_ key: String) -> String {
        guard let value = getStringMaybe(key) else {
            fatalError("Invalid value or undefined key")
        }
        
        return value
    }
    
    private func getBool(_ key: String) -> Bool {
        guard let value = getBoolMaybe(key) else {
            fatalError("Invalid value or undefined key")
        }
        
        return value
    }
    
    private func getStringMaybe(_ key: String) -> String? {
        return infoDictionary?[key] as? String
    }
    
    private func getBoolMaybe(_ key: String) -> Bool? {
        return getStringMaybe(key)?.boolValue
    }
}
