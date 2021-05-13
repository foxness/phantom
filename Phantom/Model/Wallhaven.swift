//
//  Wallhaven.swift
//  Phantom
//
//  Created by River on 2021/05/12.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

struct Wallhaven {
    private static let WALLHAVEN_ID_GROUP = "whId"
    
    // indirect example: https://wallhaven.cc/w/q22885
    // indirect regex: https://(wallhaven\.cc/w/|whvn\.cc/)(?<whId>\w+)
    
    private static let REGEX_INDIRECT = "https://(wallhaven\\.cc/w/|whvn\\.cc/)(?<\(WALLHAVEN_ID_GROUP)>\\w+)"
    
    // direct example: https://w.wallhaven.cc/full/q2/wallhaven-q22885.jpg
    // direct regex: https://w\.wallhaven\.cc/full/\w+/wallhaven-(?<whId>\w+)\.\w+
    
    private static let REGEX_DIRECT = "https://w\\.wallhaven\\.cc/full/\\w+/wallhaven-(?<\(WALLHAVEN_ID_GROUP)>\\w+)\\.\\w+"
    
    static func getThumbnailUrl(wallhavenUrl: String) -> String? {
        let regexes = [REGEX_INDIRECT, REGEX_DIRECT]
        guard let wallhavenId = Helper.extractNamedGroup(WALLHAVEN_ID_GROUP, from: wallhavenUrl, using: regexes) else { return nil }
        
        let thumbnailUrl = "https://th.wallhaven.cc/lg/\(wallhavenId.prefix(2))/\(wallhavenId).jpg"
        return thumbnailUrl
    }
    
    static func getDirectUrl(indirectWallhavenUrl: URL) throws -> String {
        let request = "wallhaven direct url"
        
        let params = Wallhaven.getDirectUrlParams(url: indirectWallhavenUrl)
        let (data, response, error) = Requests.synchronousGet(with: params)
        
        let goodData = try Helper.ensureGoodResponse(data: data, response: response, error: error, request: request)
        
        if let html = String(data: goodData, encoding: .utf8),
           let directUrl = parseDirectUrl(rawHtml: html) {
            
            return directUrl
        } else {
            throw ApiError.deserialization(request: request, raw: String(describing: String(data: goodData, encoding: .utf8)))
        }
    }
    
    private static func parseDirectUrl(rawHtml: String) -> String? {
        let startKey = "<img id=\"wallpaper\" src=\""
        let endKey = "\""
        
        guard let start = rawHtml.range(of: startKey)?.upperBound,
              let end = rawHtml.range(of: endKey, options: [], range: start..<rawHtml.endIndex , locale: nil)?.lowerBound
        else {
            return nil
        }
        
        let directUrl = String(rawHtml[start..<end])
        return directUrl
    }
    
    static func isIndirectUrl(_ url: String) -> Bool {
        return try! url.matchesRegex(REGEX_INDIRECT)
    }
    
    static func isDirectUrl(_ url: String) -> Bool {
        return try! url.matchesRegex(REGEX_DIRECT)
    }
    
    private static func getDirectUrlParams(url: URL) -> Requests.GetParams {
        return (url: url, auth: nil)
    }
}
