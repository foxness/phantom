//
//  Extensions.swift
//  Phantom
//
//  Created by user179800 on 8/29/20.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation

extension Int {
    var randomString: String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<self).map { _ in letters.randomElement()! })
    }
}

extension Dictionary where Key == String, Value == String {
    var toUrlQueryItems: [URLQueryItem] { map { URLQueryItem(name: $0.key, value: $0.value) } }
}

struct Util {
    static func p(_ string: String, _ obj: Any) {
        print("!!! \(string.uppercased()): \(obj)")
    }
    
    static func p(_ string: String) {
        print("!!! \(string.uppercased())")
    }
}

struct Requests {
    static let session = URLSession.shared
    
    static func formRequest(to url: URL, with params: [String:String], auth: (username: String, password: String)?) -> URLRequest {
        var urlc = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        urlc.queryItems = params.toUrlQueryItems
        let query = urlc.url!.query!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = Data(query.utf8)
        
        if let auth = auth {
            let authString = String(format: "%@:%@", auth.username, auth.password)
            let authBase64 = authString.data(using: String.Encoding.utf8)!.base64EncodedString()
            let authBasic = "Basic \(authBase64)"
            
            request.setValue(authBasic, forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    static func post(to url: URL, with params: [String:String], auth: (username: String, password: String)?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let request = formRequest(to: url, with: params, auth: auth)
        session.dataTask(with: request, completionHandler: completionHandler).resume()
    }
}
