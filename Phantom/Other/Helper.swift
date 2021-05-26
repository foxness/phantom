//
//  Helper.swift
//  Phantom
//
//  Created by River on 2021/04/30.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

struct Helper {
    private static let RANDOM_STATE_LENGTH = 10
    
    private init() { }
    
    static func getQueryItems(url: URL) -> [String: String] {
        let urlc = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let params = urlc.queryItems!.reduce(into: [String:String]()) { $0[$1.name] = $1.value }
        
        return params
    }
    
    static func convertExpiresIn(_ expiresIn: Int) -> Date {
        return Date(timeIntervalSinceNow: TimeInterval(expiresIn))
    }
    
    static func getRandomState(length: Int = RANDOM_STATE_LENGTH) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }
    
    static func toUrlQueryItems(query: [String: String]) -> [URLQueryItem] {
        return query.map { URLQueryItem(name: $0.key, value: $0.value) }
    }
    
    static func appendQuery(url: String, query: [String: String]) -> URL {
        var urlc = URLComponents(string: url)!
        urlc.queryItems = Helper.toUrlQueryItems(query: query)
        return urlc.url!
    }
    
    static func ensureGoodResponse(data: Data?, response: URLResponse?, error: Error?, request: String) throws -> Data {
        let httpResponse = response as! HTTPURLResponse
        
        if let error = error {
            throw PhantomError.responseHasError(request: request, error: error, data: data, response: httpResponse)
        }
        
        if !Requests.isResponseOk(httpResponse) || data == nil {
            throw PhantomError.badResponse(request: request, response: httpResponse, data: data)
        }
        
        return data!
    }
    
    static func deserializeResponse(data: Data, request: String) throws -> [String: Any] {
        var json: [String: Any]?
        let goodJson: [String: Any]
        do {
            json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            goodJson = json!
        } catch {
            throw PhantomError.deserialization(request: request, raw: String(describing: json))
        }
        
        return goodJson
    }
    
    static func isImageUrl(_ url: String) -> Bool {
        return [".jpg", ".jpeg", ".png"].contains { url.hasSuffix($0) }
    }
    
    static func extractNamedGroup(_ namedGroup: String, from string: String, using regexes: [String]) -> String? {
        for regex in regexes {
            let re = NSRegularExpression(regex)
            if let match = re.getMatch(string) {
                let range = match.range(withName: namedGroup)
                let extracted = String(string[Range(range, in: string)!])
                
                return extracted
            }
        }
        
        return nil
    }
}
