//
//  Reddit.swift
//  Phantom
//
//  Created by Rivershy on 2020/08/29.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation

// Reddit auth progression (OAuth 2):
// 1. The app loads auth page [provide: client id]
// 2. User logs in and allows the app [get: auth code]
// 3. The app fetches auth tokens [provide: auth code, get: access token, refresh token]
// - The app can submit posts & get user identity [provide: access token]
// - The app can refresh the access token [provide: refresh token, get: acesss token]

// why is Reddit a class: because I need a mutable self in a capture list of a closure in fetchAuthTokens()
// and mutable self in capture lists is impossible with structs

class Reddit {
    // MARK: - Nested entities
    
    struct AuthParams: Codable {
        let refreshToken: String
        let accessToken: String
        let accessTokenExpirationDate: Date
        
        private enum CodingKeys: String, CodingKey {
            case refreshToken, accessToken, accessTokenExpirationDate
        }
    }
    
    enum UserResponse { case none, allow, decline }
    
    // MARK: - Symbols
    
    private struct Symbols {
        static let CLIENT_SECRET = ""
        static let CODE = "code"
        static let CLIENT_ID = "client_id"
        static let RESPONSE_TYPE = "response_type"
        static let STATE = "state"
        static let REDIRECT_URI = "redirect_uri"
        static let DURATION = "duration"
        static let SCOPE = "scope"
        static let GRANT_TYPE = "grant_type"
        static let AUTHORIZATION_CODE = "authorization_code"
        static let ACCESS_TOKEN = "access_token"
        static let REFRESH_TOKEN = "refresh_token"
        static let EXPIRES_IN = "expires_in"
        static let API_TYPE = "api_type"
        static let JSON = "json"
        static let KIND = "kind"
        static let SELF = "self"
        static let RESUBMIT = "resubmit"
        static let SEND_REPLIES = "sendreplies"
        static let SUBREDDIT = "sr"
        static let TEXT = "text"
        static let TITLE = "title"
        static let BEARER = "bearer"
        static let DATA = "data"
        static let URL = "url"
        static let LINK = "link"
    }
    
    // MARK: - Constants
    
    private static let PARAM_CLIENT_ID = "XTWjw2332iSmmQ"
    private static let PARAM_REDIRECT_URI = "https://localhost/phantomdev"
    private static let PARAM_DURATION = "permanent"
    private static let PARAM_SCOPE = "identity submit"
    
    private static let ENDPOINT_AUTH = "https://www.reddit.com/api/v1/authorize.compact"
    private static let ENDPOINT_ACCESS_TOKEN = "https://www.reddit.com/api/v1/access_token"
    private static let ENDPOINT_SUBMIT = "https://oauth.reddit.com/api/submit"
    
    static let LIMIT_TITLE_LENGTH = 300
    static let LIMIT_TEXT_LENGTH = 40000
    static let LIMIT_SUBREDDIT_LENGTH = 21
    
    // MARK: - Properties
    
    private var authState: String?
    private var authCode: String?
    
    private var refreshToken: String?
    private var accessToken: String?
    private var accessTokenExpirationDate: Date?
    
    // MARK: - Computed properties
    
    var auth: AuthParams {
        AuthParams(refreshToken: refreshToken!,
                   accessToken: accessToken!,
                   accessTokenExpirationDate: accessTokenExpirationDate!)
    }
    
    var isLoggedIn: Bool { refreshToken != nil }
    
    // MARK: - Constructors
    
    init() { }
    
    init(auth: AuthParams) {
        self.refreshToken = auth.refreshToken
        self.accessToken = auth.accessToken
        self.accessTokenExpirationDate = auth.accessTokenExpirationDate
    }
    
    // MARK: - Main methods
    
    func submit(post: Post, resubmit: Bool = true, sendReplies: Bool = true) throws -> String {
        let request = "reddit submit"
        
        try ensureValidAccessToken()

        let params = getSubmitPostParams(post: post, resubmit: resubmit, sendReplies: sendReplies)
        let (data, response, error) = Requests.synchronousPost(with: params)
        
        try Helper.ensureGoodResponse(response: response, request: request)
        try Helper.ensureNoError(error: error, request: request)
        
        let json = try Helper.deserializeResponse(data: data, request: request)
        
        if let jsonDeeper = json[Symbols.JSON] as? [String: Any],
           let deeperData = jsonDeeper[Symbols.DATA] as? [String: Any],
           let postUrl = deeperData[Symbols.URL] as? String {
            
            return postUrl
        } else {
            throw ApiError.deserialization(request: request, json: json)
        }
    }
    
    // MARK: - Auth methods
    
    func getAuthUrl() -> URL {
         // https://www.reddit.com/api/v1/authorize?client_id=CLIENT_ID&response_type=TYPE&state=RANDOM_STRING&redirect_uri=URI&duration=DURATION&scope=SCOPE_STRING
         
        authState = Helper.getRandomState()
        
        let params = [Symbols.CLIENT_ID: Reddit.PARAM_CLIENT_ID,
                      Symbols.RESPONSE_TYPE: Symbols.CODE,
                      Symbols.STATE: authState!,
                      Symbols.REDIRECT_URI: Reddit.PARAM_REDIRECT_URI,
                      Symbols.DURATION: Reddit.PARAM_DURATION,
                      Symbols.SCOPE: Reddit.PARAM_SCOPE]
        
        let url = Helper.appendQuery(url: Reddit.ENDPOINT_AUTH, query: params)
        return url
    }
    
    func getUserResponse(to url: URL) -> UserResponse {
        guard url.absoluteString.hasPrefix(Reddit.PARAM_REDIRECT_URI) && authState != nil else { return .none }
        
        let params = Helper.getQueryItems(url: url)
        
        let state = params[Symbols.STATE]
        guard state != nil && state == authState else { return .none }
        
        authState = nil
        authCode = params[Symbols.CODE]
        return authCode == nil ? .decline : .allow
    }
    
    func fetchAuthTokens() throws {
        assert(authCode != nil)
        
        let request = "reddit auth token fetch"
        
        let params = getAuthTokenFetchParams()
        let (data, response, error) = Requests.synchronousPost(with: params)
        
        try Helper.ensureGoodResponse(response: response, request: request)
        try Helper.ensureNoError(error: error, request: request)
        
        let json = try Helper.deserializeResponse(data: data, request: request)
        
        if let newAccessToken = json[Symbols.ACCESS_TOKEN] as? String,
           let newRefreshToken = json[Symbols.REFRESH_TOKEN] as? String,
           let newExpiresIn = json[Symbols.EXPIRES_IN] as? Int {
            
            accessToken = newAccessToken
            refreshToken = newRefreshToken
            accessTokenExpirationDate = Helper.convertExpiresIn(newExpiresIn)
        } else {
            throw ApiError.deserialization(request: request, json: json)
        }
    }
    
    private func refreshAccessToken() throws {
        assert(refreshToken != nil)
        
        let request = "reddit access token refresh"
        
        let params = getAccessTokenRefreshParams()
        let (data, response, error) = Requests.synchronousPost(with: params)
        
        try Helper.ensureGoodResponse(response: response, request: request)
        try Helper.ensureNoError(error: error, request: request)
        
        let json = try Helper.deserializeResponse(data: data, request: request)
        
        if let newAccessToken = json[Symbols.ACCESS_TOKEN] as? String,
           let newExpiresIn = json[Symbols.EXPIRES_IN] as? Int {
            
            accessToken = newAccessToken
            accessTokenExpirationDate = Helper.convertExpiresIn(newExpiresIn)
        } else {
            throw ApiError.deserialization(request: request, json: json)
        }
    }
    
    // MARK: - Helper methods
    
    private func getAccessTokenRequestUrlAuth() -> (url: URL, auth: (username: String, password: String)) {
        let username = Reddit.PARAM_CLIENT_ID
        let password = Symbols.CLIENT_SECRET
        
        let auth = (username: username, password: password)
        let url = URL(string: Reddit.ENDPOINT_ACCESS_TOKEN)!
        
        return (url, auth)
    }
    
    private func ensureValidAccessToken() throws {
        guard accessToken == nil ||
                accessTokenExpirationDate == nil ||
                accessTokenExpirationDate! < Date()
        else {
            return
        }
        
        try refreshAccessToken()
    }
    
    private func getAccessTokenRefreshParams() -> Requests.Params {
        let data = [Symbols.GRANT_TYPE: Symbols.REFRESH_TOKEN,
                    Symbols.REFRESH_TOKEN: refreshToken!]
        
        let (url, auth) = getAccessTokenRequestUrlAuth()
        return (url, data, auth)
    }
    
    private func getAuthTokenFetchParams() -> Requests.Params {
        let data = [Symbols.GRANT_TYPE: Symbols.AUTHORIZATION_CODE,
                    Symbols.CODE: authCode!,
                    Symbols.REDIRECT_URI: Reddit.PARAM_REDIRECT_URI]
        
        let (url, auth) = getAccessTokenRequestUrlAuth()
        return (url, data, auth)
    }
    
    private func getSubmitPostParams(post: Post, resubmit: Bool, sendReplies: Bool) -> Requests.Params {
        let resubmitString = resubmit.description
        let sendRepliesString = sendReplies.description
        let subredditString = post.subreddit
        let titleString = post.title
        
        var data = [Symbols.API_TYPE: Symbols.JSON,
                    Symbols.RESUBMIT: resubmitString,
                    Symbols.SEND_REPLIES: sendRepliesString,
                    Symbols.SUBREDDIT: subredditString,
                    Symbols.TITLE: titleString]
        
        switch post.type {
        case .link:
            data[Symbols.KIND] = Symbols.LINK
            data[Symbols.URL] = post.url!
            
        case .text:
            data[Symbols.KIND] = Symbols.SELF
            data[Symbols.TEXT] = post.text ?? ""
        }
        
        let username = Symbols.BEARER
        let password = accessToken!
        
        let auth = (username: username, password: password)
        let url = URL(string: Reddit.ENDPOINT_SUBMIT)!
        return (url, data, auth)
    }
}
