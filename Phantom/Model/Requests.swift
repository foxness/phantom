//
//  Requests.swift
//  Phantom
//
//  Created by Rivershy on 2020/08/30.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation

struct Requests {
    typealias Params = (url: URL, data: [String : String], auth: (username: String, password: String)?)
    
    private static let session = URLSession.shared
    
    private init() { }
    
    static func getUserAgent() -> String {
        let identifier = Bundle.main.bundleIdentifier!
        let version = Bundle.main.releaseVersionNumber
        
        let userAgent = "iOS:\(identifier):v\(version) (by /u/DeepSpaceSignal)"
        return userAgent
    }
    
    static func isResponseOk(_ response: HTTPURLResponse) -> Bool {
        return 200..<300 ~= response.statusCode
    }
    
    static func formPostRequest(with params: Params) -> URLRequest {
        let (url, data, auth) = params
        
        var urlc = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        urlc.queryItems = data.toUrlQueryItems
        let query = urlc.url!.query!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = Data(query.utf8)
        
        let userAgent = getUserAgent()
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        if let auth = auth {
            let authHeader: String
            if auth.username == "bearer" {
                authHeader = "\(auth.username) \(auth.password)"
            } else {
                let authString = String(format: "%@:%@", auth.username, auth.password)
                let authBase64 = authString.data(using: .utf8)!.base64EncodedString()
                authHeader = "Basic \(authBase64)"
            }
            
            request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    static func post(with params: Params, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let request = formPostRequest(with: params)
        session.dataTask(with: request, completionHandler: completionHandler).resume()
    }
    
    static func formGetRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let userAgent = getUserAgent()
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        return request
    }
    
    static func get(url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let request = formGetRequest(url: url)
        session.dataTask(with: request, completionHandler: completionHandler).resume()
    }
    
    static func synchronousGet(url: URL) -> (Data?, URLResponse?, Error?) {
        var data: Data?
        var response: URLResponse?
        var error: Error?
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        
        Requests.get(url: url) { (data_, response_, error_) in
            data = data_
            response = response_
            error = error_
            
            dispatchGroup.leave()
        }
        
        dispatchGroup.wait()
        return (data, response, error)
    }
}
