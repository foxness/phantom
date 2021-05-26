//
//  Requests.swift
//  Phantom
//
//  Created by Rivershy on 2020/08/30.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation

struct Requests {
    typealias DataDict = [String: String]
    typealias DataParams = (dataDict: DataDict, dataType: DataType)
    typealias AuthParams = (username: String, password: String, basicAuth: Bool)
    typealias PostParams = (url: URL, data: DataParams, auth: AuthParams?)
    typealias GetParams = (url: URL, auth: AuthParams?)
    typealias RequestBodyWithType = (httpBody: Data, contentType: String)
    
    enum DataType {
        case multipartFormData, formUrlEncoded
    }
    
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
    
    static func getDataParams(dataDict: DataDict, dataType: DataType = .formUrlEncoded) -> DataParams {
        return (dataDict, dataType)
    }
    
    static func getAuthParams(username: String, password: String, basicAuth: Bool = false) -> AuthParams {
        return (username, password, basicAuth)
    }
    
    private static func getAuthHeader(_ auth: AuthParams) -> String {
        let (username, password, basicAuth) = auth
        
        let authHeader: String
        if basicAuth {
            let authString = "\(username):\(password)"
            let authBase64 = Data(authString.utf8).base64EncodedString()
            authHeader = "Basic \(authBase64)"
        } else {
            authHeader = "\(username) \(password)"
        }
        
        return authHeader
    }
    
    private static func getFormUrlencodedBodyWithType(dataDict: DataDict) -> RequestBodyWithType {
        let url = URL(string: "https://example.com/")! // this isn't used anywhere, but it's required
        var urlc = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        urlc.queryItems = Helper.toUrlQueryItems(query: dataDict)
        let query = urlc.url!.query!
        
        let httpBody = Data(query.utf8)
        let contentType = "application/x-www-form-urlencoded"
        
        return (httpBody, contentType)
    }
    
    private static func getMultipartFormDataBodyWithType(dataDict: DataDict) -> RequestBodyWithType {
        let randomString = UUID().uuidString
        let boundary = "Boundary-\(randomString)"

        var body = ""
        for (paramKey, paramValue) in dataDict {
            body += "--\(boundary)\r\n"
            body += "Content-Disposition:form-data; name=\"\(paramKey)\""
            body += "\r\n\r\n\(paramValue)\r\n"
        }

        body += "--\(boundary)--\r\n";

        let httpBody = Data(body.utf8)
        let contentType = "multipart/form-data; boundary=\(boundary)"
        
        return (httpBody, contentType)
    }
    
    private static func getRequestBodyWithType(data: DataParams) -> RequestBodyWithType {
        let (dataDict, dataType) = data
        
        switch dataType {
        case .formUrlEncoded:
            return getFormUrlencodedBodyWithType(dataDict: dataDict)
            
        case .multipartFormData:
            return getMultipartFormDataBodyWithType(dataDict: dataDict)
        }
    }
    
    private static func formPostRequest(with params: PostParams) -> URLRequest {
        let (url, data, auth) = params
        
        let (httpBody, contentType) = getRequestBodyWithType(data: data)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = httpBody
        
        setContentType(for: &request, contentType: contentType)
        setUserAgent(for: &request)
        setAuthHeader(for: &request, auth: auth)
        
        return request
    }
    
    static func postAsync(with params: PostParams, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let request = formPostRequest(with: params)
        session.dataTask(with: request, completionHandler: completionHandler).resume()
    }
    
    static func postSync(with params: PostParams) -> (Data?, URLResponse?, Error?) {
        var data: Data?
        var response: URLResponse?
        var error: Error?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        Requests.postAsync(with: params) { (data_, response_, error_) in
            data = data_
            response = response_
            error = error_
            
            semaphore.signal()
        }
        
        semaphore.wait()
        
        return (data, response, error)
    }
    
    private static func formGetRequest(with params: GetParams) -> URLRequest {
        var request = URLRequest(url: params.url)
        request.httpMethod = "GET"
        
        setUserAgent(for: &request)
        setAuthHeader(for: &request, auth: params.auth)
        
        return request
    }
    
    static func getAsync(with params: GetParams, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let request = formGetRequest(with: params)
        session.dataTask(with: request, completionHandler: completionHandler).resume()
    }
    
    static func getSync(with params: GetParams) -> (Data?, URLResponse?, Error?) {
        var data: Data?
        var response: URLResponse?
        var error: Error?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        Requests.getAsync(with: params) { (data_, response_, error_) in
            data = data_
            response = response_
            error = error_
            
            semaphore.signal()
        }
        
        semaphore.wait()
        
        return (data, response, error)
    }
    
    private static func setUserAgent(for request: inout URLRequest) {
        let userAgent = getUserAgent()
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
    }
    
    private static func setAuthHeader(for request: inout URLRequest, auth: AuthParams?) {
        guard let auth = auth else { return }
        
        let authHeader = getAuthHeader(auth)
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
    }
    
    private static func setContentType(for request: inout URLRequest, contentType: String) {
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
    }
}
