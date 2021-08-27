//
//  AppVariables.swift
//  Phantom
//
//  Created by River on 2021/08/27.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

struct AppVariables {
    // MARK: - Build identifiers
    
    static var version: String { Bundle.main.prettyAppVersion }
    static var config: String { Bundle.main.config }
    
    static var userAgent: String {
        let identifier = Bundle.main.bundleIdentifier!
        let version = Bundle.main.releaseVersionNumber
        
        return "ios:\(identifier):v\(version) (by /u/DeepSpaceSignal)" // todo: extract username [ez]
    }
}

extension Bundle {
    // MARK: - Default keys
    private static let KEY_RELEASE_VERSION_NUMBER = "CFBundleShortVersionString"
    private static let KEY_BUILD_VERSION_NUMBER = "CFBundleVersion"
    
    // MARK: - Custom keys
    private static let KEY_PHANTOM_CONFIG = "PhantomConfig"
    
    // MARK: - Default variables
    
    var releaseVersionNumber: String { getString(Bundle.KEY_RELEASE_VERSION_NUMBER)! }
    var buildVersionNumber: String { getString(Bundle.KEY_BUILD_VERSION_NUMBER)! }
    
    // MARK: - Custom variables
    
    var config: String { getString(Bundle.KEY_PHANTOM_CONFIG)! }
    
    // MARK: - Custom computed variables
    
    var prettyAppVersion: String {
        return "\(releaseVersionNumber) (\(buildVersionNumber))"
    }
    
    // MARK: - Helper
    
    func getString(_ key: String) -> String? {
        return infoDictionary?[key] as? String
    }
}
