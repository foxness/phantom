//
//  Requests.swift
//  Phantom
//
//  Created by Rivershy on 2020/08/30.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation

struct Requests {
    typealias PostParams = (url: URL, data: [String : String], auth: (username: String, password: String)?)
    typealias GetParams = (url: URL, auth: (username: String, password: String)?)
    
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
    
    private static func getAuthField(username: String, password: String) -> String {
        let authHeader: String
        if username == "bearer" {
            authHeader = "\(username) \(password)"
        } else {
            let authString = String(format: "%@:%@", username, password)
            let authBase64 = authString.data(using: .utf8)!.base64EncodedString()
            authHeader = "Basic \(authBase64)"
        }
        
        return authHeader
    }
    
    static func formPostRequest(with params: PostParams) -> URLRequest {
        let (url, data, auth) = params
        
        var urlc = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        urlc.queryItems = Helper.toUrlQueryItems(query: data)
        let query = urlc.url!.query!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = Data(query.utf8)
        
        let userAgent = getUserAgent()
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        if let auth = auth {
            let authHeader = getAuthField(username: auth.username, password: auth.password)
            request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    static func post(with params: PostParams, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let request = formPostRequest(with: params)
        session.dataTask(with: request, completionHandler: completionHandler).resume()
    }
    
    static func synchronousPost(with params: PostParams) -> (Data?, URLResponse?, Error?) {
        var data: Data?
        var response: URLResponse?
        var error: Error?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        Requests.post(with: params) { (data_, response_, error_) in
            data = data_
            response = response_
            error = error_
            
            semaphore.signal()
        }
        
        semaphore.wait()
        
        return (data, response, error)
    }
    
    static func formGetRequest(with params: GetParams) -> URLRequest {
        var request = URLRequest(url: params.url)
        request.httpMethod = "GET"
        
        let userAgent = getUserAgent()
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        if let auth = params.auth {
            let authHeader = getAuthField(username: auth.username, password: auth.password)
            request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    static func get(with params: GetParams, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let request = formGetRequest(with: params)
        session.dataTask(with: request, completionHandler: completionHandler).resume()
    }
    
    static func synchronousGet(with params: GetParams) -> (Data?, URLResponse?, Error?) {
        var data: Data?
        var response: URLResponse?
        var error: Error?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        Requests.get(with: params) { (data_, response_, error_) in
            data = data_
            response = response_
            error = error_
            
            semaphore.signal()
        }
        
        semaphore.wait()
        
        return (data, response, error)
    }
    
//    static func formPostRequest2(with params: PostParams) -> URLRequest {
//        let (url, data, auth) = params
//
//        let boundary = "Boundary-\(UUID().uuidString)"
//
//        var body = ""
//        for (paramKey, paramValue) in data {
//            body += "--\(boundary)\r\n"
//            body += "Content-Disposition:form-data; name=\"\(paramKey)\""
//            body += "\r\n\r\n\(paramValue)\r\n"
//        }
//
//        body += "--\(boundary)--\r\n";
//
//        let httpBody = body.data(using: .utf8)
//
//        var request = URLRequest(url: url)
//        request.setValue("\(auth!.username) \(auth!.password)", forHTTPHeaderField: "Authorization")
//        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
//
//        request.httpMethod = "POST"
//        request.httpBody = httpBody
//
//        let userAgent = getUserAgent()
//        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
//
//        return request
//    }
//
//    static func post2(with params: PostParams, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
//        let request = formPostRequest2(with: params)
//        session.dataTask(with: request, completionHandler: completionHandler).resume()
//    }
//
//    static func synchronousPost2(with params: PostParams) -> (Data?, URLResponse?, Error?) {
//        var data: Data?
//        var response: URLResponse?
//        var error: Error?
//
//        let semaphore = DispatchSemaphore(value: 0)
//
//        Requests.post2(with: params) { (data_, response_, error_) in
//            data = data_
//            response = response_
//            error = error_
//
//            semaphore.signal()
//        }
//
//        semaphore.wait()
//
//        return (data, response, error)
//    }
}
