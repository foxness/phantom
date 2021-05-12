//
//  Wallhaven.swift
//  Phantom
//
//  Created by River on 2021/05/12.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

struct Wallhaven {
    static func getThumbnailUrl(wallhavenUrl: String) -> String? {
        guard let wallhavenId = getWallhavenId(wallhavenUrl: wallhavenUrl) else { return nil }
        
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
        return matchIndirectUrl(url) != nil
    }
    
    static func isDirectUrl(_ url: String) -> Bool {
        return matchDirectUrl(url) != nil
    }
    
    private static func getWallhavenId(wallhavenUrl: String) -> String? {
        var possibleMatch: NSTextCheckingResult? = nil
        if let indirectMatch = matchIndirectUrl(wallhavenUrl) {
            possibleMatch = indirectMatch
        } else if let directMatch = matchDirectUrl(wallhavenUrl) {
            possibleMatch = directMatch
        }
        
        guard let match = possibleMatch else { return nil }
        
        let range = match.range(withName: "whId")
        let wallhavenId = String(wallhavenUrl[Range(range, in: wallhavenUrl)!])
        
        return wallhavenId
    }
    
    private static func matchIndirectUrl(_ url: String) -> NSTextCheckingResult? {
        // indirect: https://wallhaven.cc/w/q22885
        // regex: https://(wallhaven\.cc/w/|whvn\.cc/)(?<whId>\w+)
        
        let indirectRegex = "https://(wallhaven\\.cc/w/|whvn\\.cc/)(?<whId>\\w+)" // must have whId named capture group
        
        let regex = NSRegularExpression(indirectRegex)
        let match = regex.getMatch(url)
        return match
    }
    
    private static func matchDirectUrl(_ url: String) -> NSTextCheckingResult? {
        // direct: https://w.wallhaven.cc/full/q2/wallhaven-q22885.jpg
        // regex: https://w\.wallhaven\.cc/full/\w+/wallhaven-(?<whId>\w+)\.\w+
        
        let directRegex = "https://w\\.wallhaven\\.cc/full/\\w+/wallhaven-(?<whId>\\w+)\\.\\w+" // must have whId named capture group
        
        let regex = NSRegularExpression(directRegex)
        let match = regex.getMatch(url)
        return match
    }
    
    private static func getDirectUrlParams(url: URL) -> Requests.GetParams {
        return (url: url, auth: nil)
    }
}
