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
    
    static var config: String { Bundle.main.config }
    
    static var version: String {
        let version = Bundle.main.releaseVersionNumber
        let build = Bundle.main.buildVersionNumber
        let config = config
        
        let configString = config == "stable" ? "" : " (\(config))"
        
        return "\(version) (\(build))\(configString)"
    }
    
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
    
    fileprivate var releaseVersionNumber: String { getString(Bundle.KEY_RELEASE_VERSION_NUMBER)! }
    fileprivate var buildVersionNumber: String { getString(Bundle.KEY_BUILD_VERSION_NUMBER)! }
    
    // MARK: - Custom variables
    
    fileprivate var config: String { getString(Bundle.KEY_PHANTOM_CONFIG)! }
    
    // MARK: - Helper
    
    private func getString(_ key: String) -> String? {
        return infoDictionary?[key] as? String
    }
}
