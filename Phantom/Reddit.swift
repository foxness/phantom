//
//  Reddit.swift
//  Phantom
//
//  Created by user179800 on 8/29/20.
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
    struct AuthParams: Codable {
        let refreshToken: String
        let accessToken: String
        let accessTokenExpirationDate: Date
        
        private enum CodingKeys: String, CodingKey {
            case refreshToken, accessToken, accessTokenExpirationDate
        }
    }
    
    enum UserResponse { case none, allow, decline }
    
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
    }
    
    private static let PARAM_CLIENT_ID = "XTWjw2332iSmmQ"
    private static let PARAM_REDIRECT_URI = "https://localhost/phantomdev"
    private static let PARAM_DURATION = "permanent"
    private static let PARAM_SCOPE = "identity submit"
    
    private static let ENDPOINT_AUTH = "https://www.reddit.com/api/v1/authorize.compact"
    private static let ENDPOINT_ACCESS_TOKEN = "https://www.reddit.com/api/v1/access_token"
    private static let ENDPOINT_SUBMIT = "https://oauth.reddit.com/api/submit"
    
    private static let RANDOM_STATE_LENGTH = 10
    
    static let LIMIT_TITLE_LENGTH = 300
    static let LIMIT_TEXT_LENGTH = 40000
    static let LIMIT_SUBREDDIT_LENGTH = 21
    
    private var authState: String?
    private var authCode: String?
    
    private var refreshToken: String?
    private var accessToken: String?
    private var accessTokenExpirationDate: Date?
    
    var auth: AuthParams {
        AuthParams(refreshToken: refreshToken!,
                   accessToken: accessToken!,
                   accessTokenExpirationDate: accessTokenExpirationDate!)
    }
    
    private var randomState: String { Reddit.RANDOM_STATE_LENGTH.randomString }
    
    var isLoggedIn: Bool { refreshToken != nil }
    
    init() { }
    
    init(auth: AuthParams) {
        self.refreshToken = auth.refreshToken
        self.accessToken = auth.accessToken
        self.accessTokenExpirationDate = auth.accessTokenExpirationDate
    }
    
    func getAuthUrl() -> URL {
         // https://www.reddit.com/api/v1/authorize?client_id=CLIENT_ID&response_type=TYPE&state=RANDOM_STRING&redirect_uri=URI&duration=DURATION&scope=SCOPE_STRING
         
        authState = randomState
        
        let params = [Symbols.CLIENT_ID: Reddit.PARAM_CLIENT_ID,
                      Symbols.RESPONSE_TYPE: Symbols.CODE,
                      Symbols.STATE: authState!,
                      Symbols.REDIRECT_URI: Reddit.PARAM_REDIRECT_URI,
                      Symbols.DURATION: Reddit.PARAM_DURATION,
                      Symbols.SCOPE: Reddit.PARAM_SCOPE]
        
        var urlc = URLComponents(string: Reddit.ENDPOINT_AUTH)!
        urlc.queryItems = params.toUrlQueryItems
        return urlc.url!
    }
    
    func getUserResponse(to url: URL) -> UserResponse {
        guard url.absoluteString.hasPrefix(Reddit.PARAM_REDIRECT_URI) && authState != nil else { return .none }
        
        let urlc = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let params = urlc.queryItems!.reduce(into: [String:String]()) { $0[$1.name] = $1.value }
        
        let state = params[Symbols.STATE]
        guard state != nil && state == authState else { return .none }
        
        authState = nil
        authCode = params[Symbols.CODE]
        return authCode == nil ? .decline : .allow
    }
    
    private func getAccessTokenRequestUrlAuth() -> (url: URL, auth: (username: String, password: String)) {
        let username = Reddit.PARAM_CLIENT_ID
        let password = Symbols.CLIENT_SECRET
        
        let auth = (username: username, password: password)
        let url = URL(string: Reddit.ENDPOINT_ACCESS_TOKEN)!
        
        return (url, auth)
    }
    
    private func getAuthTokenFetchParams() -> Requests.Params {
        let data = [Symbols.GRANT_TYPE: Symbols.AUTHORIZATION_CODE,
                    Symbols.CODE: authCode!,
                    Symbols.REDIRECT_URI: Reddit.PARAM_REDIRECT_URI]
        
        let (url, auth) = getAccessTokenRequestUrlAuth()
        return (url, data, auth)
    }
    
    func fetchAuthTokens(callback: @escaping () -> Void) {
        assert(authCode != nil)
        
        let params = getAuthTokenFetchParams()
        Requests.post(with: params) { (data, response, error) in
            let response = response as! HTTPURLResponse
            if Requests.isResponseOk(response) {
                Log.p("auth token fetch: http ok")
            } else {
                Log.p("auth token fetch: http not ok, status code: \(response.statusCode), response", response)
            }
            
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                    Log.p("json", json)
                    
                    let newAccessToken = json[Symbols.ACCESS_TOKEN] as! String
                    let newRefreshToken = json[Symbols.REFRESH_TOKEN] as! String
                    let newExpiresIn = json[Symbols.EXPIRES_IN] as! Int
                    
                    self.accessToken = newAccessToken
                    self.refreshToken = newRefreshToken
                    self.accessTokenExpirationDate = Reddit.convertExpiresIn(newExpiresIn)
                    
                    Log.p("auth token fetch: all good")
                } catch {
                    Log.p("auth token fetch error", error)
                }
            } else if let error = error {
                Log.p("auth token fetch error 2", error)
            }
            
            callback()
        }
    }
    
    private static func convertExpiresIn(_ expiresIn: Int) -> Date {
        Date(timeIntervalSinceNow: TimeInterval(expiresIn))
    }
    
    private func ensureValidAccessToken(callback: @escaping () -> Void) {
        guard accessToken == nil || accessTokenExpirationDate == nil || accessTokenExpirationDate! < Date() else {
            callback()
            return
        }
        
        refreshAccessToken(callback: callback)
    }
    
    private func getAccessTokenRefreshParams() -> Requests.Params {
        let data = [Symbols.GRANT_TYPE: Symbols.REFRESH_TOKEN,
                    Symbols.REFRESH_TOKEN: refreshToken!]
        
        let (url, auth) = getAccessTokenRequestUrlAuth()
        return (url, data, auth)
    }
    
    private func refreshAccessToken(callback: @escaping () -> Void) {
        assert(refreshToken != nil)
        
        let params = getAccessTokenRefreshParams()
        Requests.post(with: params) { (data, response, error) in
            let response = response as! HTTPURLResponse
            if Requests.isResponseOk(response) {
                Log.p("access token refresh: http ok")
            } else {
                Log.p("access token refresh: http not ok, status code: \(response.statusCode), response", response)
            }
            
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                    Log.p("json", json)
                    
                    let newAccessToken = json[Symbols.ACCESS_TOKEN] as! String
                    let newExpiresIn = json[Symbols.EXPIRES_IN] as! Int
                    
                    self.accessToken = newAccessToken
                    self.accessTokenExpirationDate = Reddit.convertExpiresIn(newExpiresIn)
                    
                    Log.p("access token refresh: all good")
                    Log.p("accesstoken", newAccessToken)
                    Log.p("expiration", self.accessTokenExpirationDate!)
                } catch {
                    Log.p("access token refresh error", error)
                }
            } else if let error = error {
                Log.p("access token refresh error 2", error)
            }
            
            callback()
        }
    }
    
    private func getSubmitPostParams(post: Post, resubmit: Bool, sendReplies: Bool) -> Requests.Params {
        let resubmitString = resubmit.description
        let sendRepliesString = sendReplies.description
        let subredditString = post.subreddit
        let textString = post.text
        let titleString = post.title
        
        let data = [Symbols.API_TYPE: Symbols.JSON,
                    Symbols.KIND: Symbols.SELF,
                    Symbols.RESUBMIT: resubmitString,
                    Symbols.SEND_REPLIES: sendRepliesString,
                    Symbols.SUBREDDIT: subredditString,
                    Symbols.TEXT: textString,
                    Symbols.TITLE: titleString]
        
        let username = Symbols.BEARER
        let password = accessToken!
        
        let auth = (username: username, password: password)
        let url = URL(string: Reddit.ENDPOINT_SUBMIT)!
        return (url, data, auth)
    }
    
    func submit(post: Post, resubmit: Bool = true, sendReplies: Bool = true, callback: @escaping (String?) -> Void) {
        ensureValidAccessToken {
            let params = self.getSubmitPostParams(post: post, resubmit: resubmit, sendReplies: sendReplies)
            Requests.post(with: params) { (data, response, error) in
                var url: String? = nil
                let response = response as! HTTPURLResponse
                
                if Requests.isResponseOk(response) {
                    Log.p("post submit: http ok")
                } else {
                    Log.p("post submit: http not ok, status code: \(response.statusCode), response", response)
                }
                
                if let data = data {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                        Log.p("json", json)
                        
                        let jsonDeeper = json[Symbols.JSON] as! [String: Any]
                        let deeperData = jsonDeeper[Symbols.DATA] as! [String: Any]
                        let postUrl = deeperData[Symbols.URL] as! String
                        url = postUrl
                    } catch {
                        Log.p("post submit error", error)
                    }
                } else if let error = error {
                    Log.p("post submit error 2", error)
                }
                
                callback(url)
            }
        }
    }
}
