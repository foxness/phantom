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
        Log.p("useragent", userAgent)
        return userAgent
    }
    
    static func isResponseOk(_ response: HTTPURLResponse) -> Bool { 200..<300 ~= response.statusCode }
    
    static func formRequest(with params: Params) -> URLRequest {
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
        let request = formRequest(with: params)
        session.dataTask(with: request, completionHandler: completionHandler).resume()
    }
}
