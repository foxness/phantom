//
//  Requests.swift
//  Phantom
//
//  Created by user179800 on 8/30/20.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation

struct Requests {
    typealias Params = (url: URL, data: [String : String], auth: (username: String, password: String)?)
    
    static let USER_AGENT = "ios:me.rivershy.Phantom:v0.0.1 (by /u/DeepSpaceSignal)"
    
    static let session = URLSession.shared
    
    static func formRequest(with params: Params) -> URLRequest {
        let (url, data, auth) = params
        
        var urlc = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        urlc.queryItems = data.toUrlQueryItems
        let query = urlc.url!.query!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = Data(query.utf8)
        request.setValue(Requests.USER_AGENT, forHTTPHeaderField: "User-Agent")
        
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
