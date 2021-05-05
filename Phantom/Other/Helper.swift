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
    
    static func ensureGoodResponse(response: URLResponse?, request: String) throws {
        let httpResponse = response as! HTTPURLResponse
        if Requests.isResponseOk(httpResponse) {
            Log.p("\(request): http ok")
        } else {
            throw ApiError.badResponse(request: request, statusCode: httpResponse.statusCode, response: httpResponse)
        }
    }
    
    static func ensureNoError(error: Error?, request: String) throws {
        if let error = error {
            throw ApiError.request(request: request, error: error)
        }
    }
    
    static func deserializeResponse(data: Data?, request: String) throws -> [String: Any] {
        guard let data = data else {
            throw ApiError.noData(request: request)
        }
        
        var json: [String: Any]?
        let goodJson: [String: Any]
        do {
            json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            goodJson = json!
        } catch {
            throw ApiError.deserialization(request: request, raw: String(describing: json))
        }
        
        return goodJson
    }
}

enum ApiError: Error {
    case badResponse(request: String, statusCode: Int, response: HTTPURLResponse)
    case request(request: String, error: Error)
    case noData(request: String)
    case deserialization(request: String, raw: String)
}
