//
//  Wallhaven.swift
//  Phantom
//
//  Created by River on 2021/05/12.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

struct Wallhaven {
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
        // indirect: https://wallhaven.cc/w/q22885
        // regex: https://(wallhaven\.cc/w/|whvn\.cc/)\w+
        
        let indirectRegex = "https://(wallhaven\\.cc/w/|whvn\\.cc/)\\w+"
        
        let matches = try! url.matchesRegex(indirectRegex)
        return matches
    }
    
    static func isDirectUrl(_ url: String) -> Bool {
        // direct: https://w.wallhaven.cc/full/q2/wallhaven-q22885.jpg
        // regex: https://w\.wallhaven\.cc/full/\w+/wallhaven-\w+\.\w+
        
        let directPattern = "https://w\\.wallhaven\\.cc/full/\\w+/wallhaven-\\w+\\.\\w+"
        
        let matches = try! url.matchesRegex(directPattern)
        return matches
    }
    
    private static func getDirectUrlParams(url: URL) -> Requests.GetParams {
        return (url: url, auth: nil)
    }
}
