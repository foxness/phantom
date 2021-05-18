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
        let username: String
        
        private enum CodingKeys: String, CodingKey {
            case refreshToken, accessToken, accessTokenExpirationDate, username
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
        static let NAME = "name"
    }
    
    // MARK: - Constants
    
    private static let PARAM_CLIENT_ID = "XTWjw2332iSmmQ"
    private static let PARAM_REDIRECT_URI = "https://localhost/phantomdev"
    private static let PARAM_DURATION = "permanent"
    private static let PARAM_SCOPE = "identity submit"
    
    private static let ENDPOINT_AUTH = "https://www.reddit.com/api/v1/authorize.compact"
    private static let ENDPOINT_ACCESS_TOKEN = "https://www.reddit.com/api/v1/access_token"
    private static let ENDPOINT_SUBMIT = "https://oauth.reddit.com/api/submit"
    private static let ENDPOINT_IDENTITY = "https://oauth.reddit.com/api/v1/me"
    
    static let LIMIT_TITLE_LENGTH = 300
    static let LIMIT_TEXT_LENGTH = 40000
    static let LIMIT_SUBREDDIT_LENGTH = 21
    
    // MARK: - Properties
    
    private var authState: String?
    private var authCode: String?
    
    private var refreshToken: String?
    private var accessToken: String?
    private var accessTokenExpirationDate: Date?
    
    private(set) var username: String?
    
    // MARK: - Computed properties
    
    var auth: AuthParams? {
        guard isLoggedIn else { return nil }
        
        return AuthParams(refreshToken: refreshToken!,
                          accessToken: accessToken!,
                          accessTokenExpirationDate: accessTokenExpirationDate!,
                          username: username!)
    }
    
    var isLoggedIn: Bool { refreshToken != nil }
    
    // MARK: - Constructors
    
    init() { }
    
    init(auth: AuthParams) {
        self.refreshToken = auth.refreshToken
        self.accessToken = auth.accessToken
        self.accessTokenExpirationDate = auth.accessTokenExpirationDate
        self.username = auth.username
    }
    
    // MARK: - Main methods
    
    func submit(post: Post, resubmit: Bool = true, sendReplies: Bool = true) throws -> String {
        assert(isLoggedIn) // todo: throw error instead if not logged in
        
        let request = "reddit submit"
        
        try ensureValidAccessToken()

        let params = getSubmitPostParams(post: post, resubmit: resubmit, sendReplies: sendReplies)
        let (data, response, error) = Requests.synchronousPost(with: params)
        
        let goodData = try Helper.ensureGoodResponse(data: data, response: response, error: error, request: request)
        let json = try Helper.deserializeResponse(data: goodData, request: request)
        let postUrl = try Reddit.deserializeSubmitResponse(json: json, request: request)
        
        return postUrl
    }
    
    func getIdentity() throws { // identity = account username
        assert(isLoggedIn) // todo: throw error instead if not logged in
        
        let request = "reddit identity"
        
        try ensureValidAccessToken()

        let params = getIdentityParams()
        let (data, response, error) = Requests.synchronousGet(with: params)
        
        let goodData = try Helper.ensureGoodResponse(data: data, response: response, error: error, request: request)
        let json = try Helper.deserializeResponse(data: goodData, request: request)
        username = try Reddit.deserializeIdentityResponse(json: json, request: request)
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
        
        let (state, code) = Reddit.deserializeAuthResponse(url: url, request: "reddit user response")
        authCode = code

        guard state != nil && state == authState else { return .none }
        authState = nil
        
        let response: UserResponse = code == nil ? .decline : .allow
        return response
    }
    
    func fetchAuthTokens() throws {
        assert(authCode != nil)
        
        let request = "reddit auth token fetch"
        
        let params = getAuthTokenFetchParams()
        let (data, response, error) = Requests.synchronousPost(with: params)
        
        let goodData = try Helper.ensureGoodResponse(data: data, response: response, error: error, request: request)
        let json = try Helper.deserializeResponse(data: goodData, request: request)
        let (newAccessToken, newExpirationDate, newRefreshToken) = try Reddit.deserializeAuthTokens(json: json, request: request)
        
        accessToken = newAccessToken
        accessTokenExpirationDate = newExpirationDate
        refreshToken = newRefreshToken
    }
    
    private func refreshAccessToken() throws {
        assert(isLoggedIn)
        
        let request = "reddit access token refresh"
        
        let params = getAccessTokenRefreshParams()
        let (data, response, error) = Requests.synchronousPost(with: params)
        
        let goodData = try Helper.ensureGoodResponse(data: data, response: response, error: error, request: request)
        let json = try Helper.deserializeResponse(data: goodData, request: request)
        let (newAccessToken, newAccessTokenExpirationDate) = try Reddit.deserializeAccessToken(json: json, request: request)
        
        accessToken = newAccessToken
        accessTokenExpirationDate = newAccessTokenExpirationDate
    }
    
    func logout() {
        assert(isLoggedIn)
        
        authCode = nil
        refreshToken = nil
        accessToken = nil
        accessTokenExpirationDate = nil
    }
    
    // MARK: - Deserializer methods
    
    private static func deserializeAccessToken(json: [String: Any], request: String) throws -> (accessToken: String, expirationDate: Date) {
        guard let accessToken = json[Symbols.ACCESS_TOKEN] as? String,
              let expiresIn = json[Symbols.EXPIRES_IN] as? Int
        else {
            throw PhantomError.deserialization(request: request, raw: String(describing: json))
        }
            
        let expirationDate = Helper.convertExpiresIn(expiresIn)
        return (accessToken: accessToken, expirationDate: expirationDate)
    }
    
    private static func deserializeAuthTokens(json: [String: Any], request: String) throws -> (accessToken: String, expirationDate: Date, refreshToken: String) {
        guard let accessToken = json[Symbols.ACCESS_TOKEN] as? String,
              let refreshToken = json[Symbols.REFRESH_TOKEN] as? String,
              let expiresIn = json[Symbols.EXPIRES_IN] as? Int
        else {
            throw PhantomError.deserialization(request: request, raw: String(describing: json))
        }
        
        let expirationDate = Helper.convertExpiresIn(expiresIn)
        return (accessToken: accessToken, expirationDate: expirationDate, refreshToken: refreshToken)
    }
    
    private static func deserializeSubmitResponse(json: [String: Any], request: String) throws -> String {
        guard let jsonDeeper = json[Symbols.JSON] as? [String: Any],
              let deeperData = jsonDeeper[Symbols.DATA] as? [String: Any],
              let postUrl = deeperData[Symbols.URL] as? String
        else {
            throw PhantomError.deserialization(request: request, raw: String(describing: json))
        }
            
        return postUrl
    }
    
    private static func deserializeIdentityResponse(json: [String: Any], request: String) throws -> String {
        guard let username = json[Symbols.NAME] as? String else {
            throw PhantomError.deserialization(request: request, raw: String(describing: json))
        }
            
        return username
    }
    
    private static func deserializeAuthResponse(url: URL, request: String) -> (state: String?, code: String?) {
        let params = Helper.getQueryItems(url: url)
        
        let state = params[Symbols.STATE]
        let code = params[Symbols.CODE]
        
        return (state: state, code: code)
    }
    
    // MARK: - Helper methods
    
    private func getAccessTokenRequestUrlAuth() -> (url: URL, auth: (username: String, password: String)) {
        let username = Reddit.PARAM_CLIENT_ID
        let password = Symbols.CLIENT_SECRET
        
        let auth = (username: username, password: password)
        let url = URL(string: Reddit.ENDPOINT_ACCESS_TOKEN)!
        
        return (url, auth)
    }
    
    private func getBearerAuth() -> (username: String, password: String) {
        return (username: Symbols.BEARER, password: accessToken!)
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
    
    private func getAccessTokenRefreshParams() -> Requests.PostParams {
        let data = [Symbols.GRANT_TYPE: Symbols.REFRESH_TOKEN,
                    Symbols.REFRESH_TOKEN: refreshToken!]
        
        let (url, auth) = getAccessTokenRequestUrlAuth()
        return (url, data, auth)
    }
    
    private func getAuthTokenFetchParams() -> Requests.PostParams {
        let data = [Symbols.GRANT_TYPE: Symbols.AUTHORIZATION_CODE,
                    Symbols.CODE: authCode!,
                    Symbols.REDIRECT_URI: Reddit.PARAM_REDIRECT_URI]
        
        let (url, auth) = getAccessTokenRequestUrlAuth()
        return (url, data, auth)
    }
    
    private func getSubmitPostParams(post: Post, resubmit: Bool, sendReplies: Bool) -> Requests.PostParams {
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
        
        let auth = getBearerAuth()
        let url = URL(string: Reddit.ENDPOINT_SUBMIT)!
        return (url, data, auth)
    }
    
    private func getIdentityParams() -> Requests.GetParams {
        let auth = getBearerAuth()
        let url = URL(string: Reddit.ENDPOINT_IDENTITY)!
        
        return (url, auth)
    }
}
