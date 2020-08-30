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
    enum UserResponse { case none, allow, decline }
    
    static let PARAM_CLIENT_ID = "XTWjw2332iSmmQ"
    static let PARAM_REDIRECT_URI = "https://localhost/phantomdev"
    static let PARAM_DURATION = "permanent"
    static let PARAM_SCOPE = "identity submit"
    
    static let SYMBOL_CLIENT_SECRET = ""
    static let SYMBOL_CODE = "code"
    static let SYMBOL_CLIENT_ID = "client_id"
    static let SYMBOL_RESPONSE_TYPE = "response_type"
    static let SYMBOL_STATE = "state"
    static let SYMBOL_REDIRECT_URI = "redirect_uri"
    static let SYMBOL_DURATION = "duration"
    static let SYMBOL_SCOPE = "scope"
    static let SYMBOL_GRANT_TYPE = "grant_type"
    static let SYMBOL_AUTHORIZATION_CODE = "authorization_code"
    
    static let ENDPOINT_AUTH = "https://www.reddit.com/api/v1/authorize.compact"
    static let ENDPOINT_ACCESS_TOKEN = "https://www.reddit.com/api/v1/access_token"
    
    static let RANDOM_STATE_LENGTH = 10
    
    var authState: String?
    var authCode: String?
    
    var accessToken: String?
    var refreshToken: String?
    var accessTokenExpirationDate: Date?
    
    var randomState: String { Reddit.RANDOM_STATE_LENGTH.randomString }
    
    func getAuthUrl() -> URL {
         // https://www.reddit.com/api/v1/authorize?client_id=CLIENT_ID&response_type=TYPE&state=RANDOM_STRING&redirect_uri=URI&duration=DURATION&scope=SCOPE_STRING
         
        authState = randomState
        
        let params = [Reddit.SYMBOL_CLIENT_ID: Reddit.PARAM_CLIENT_ID,
                      Reddit.SYMBOL_RESPONSE_TYPE: Reddit.SYMBOL_CODE,
                      Reddit.SYMBOL_STATE: authState!,
                      Reddit.SYMBOL_REDIRECT_URI: Reddit.PARAM_REDIRECT_URI,
                      Reddit.SYMBOL_DURATION: Reddit.PARAM_DURATION,
                      Reddit.SYMBOL_SCOPE: Reddit.PARAM_SCOPE]
        
        var urlc = URLComponents(string: Reddit.ENDPOINT_AUTH)!
        urlc.queryItems = params.toUrlQueryItems
        return urlc.url!
    }
    
    func getUserResponse(to url: URL) -> UserResponse {
        guard url.absoluteString.hasPrefix(Reddit.PARAM_REDIRECT_URI) && authState != nil else { return .none }
        
        let urlc = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let params = urlc.queryItems!.reduce(into: [String:String]()) { $0[$1.name] = $1.value }
        
        let state = params[Reddit.SYMBOL_STATE]
        guard state != nil && state == authState else { return .none }
        
        authState = nil
        authCode = params[Reddit.SYMBOL_CODE]
        return authCode == nil ? .decline : .allow
    }
    
    func getAuthTokenFetchParams() -> Requests.Params {
        let data = [Reddit.SYMBOL_GRANT_TYPE: Reddit.SYMBOL_AUTHORIZATION_CODE,
                      Reddit.SYMBOL_CODE: authCode!,
                      Reddit.SYMBOL_REDIRECT_URI: Reddit.PARAM_REDIRECT_URI]
        
        let username = Reddit.PARAM_CLIENT_ID
        let password = Reddit.SYMBOL_CLIENT_SECRET
        
        let auth = (username: username, password: password)
        let url = URL(string: Reddit.ENDPOINT_ACCESS_TOKEN)!
        
        return (url, data, auth)
    }
    
    func fetchAuthTokens(callback: @escaping () -> Void) {
        assert(authCode != nil)
        
        let params = getAuthTokenFetchParams()
        Requests.post(with: params) { (data, response, error) in
            if let response = response as? HTTPURLResponse {
                if 200..<300 ~= response.statusCode { // HTTP OK
                    Util.p("auth token fetch: http ok")
                } else {
                    Util.p("auth token fetch: http not ok, status code: \(response.statusCode), response", response)
                }
            } else {
                Util.p("auth token fetch: something's fucky")
            }
            
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                    Util.p("json", json)
                    
                    let newAccessToken = json["access_token"] as! String
                    let newRefreshToken = json["refresh_token"] as! String
                    let newExpiresIn = json["expires_in"] as! Int
                    
                    self.accessToken = newAccessToken
                    self.refreshToken = newRefreshToken
                    self.accessTokenExpirationDate = Reddit.convertExpiresIn(newExpiresIn)
                    
                    Util.p("auth token fetch: all good")
                } catch {
                    Util.p("auth token fetch error", error)
                }
            } else if let error = error {
                Util.p("auth token fetch error 2", error)
            }
            
            callback()
        }
    }
    
    static func convertExpiresIn(_ expiresIn: Int) -> Date {
        Date(timeIntervalSinceNow: TimeInterval(expiresIn))
    }
    
    func ensureValidAccessToken(callback: @escaping () -> Void) {
        guard accessToken == nil || accessTokenExpirationDate == nil || accessTokenExpirationDate! < Date() else {
            callback()
            return
        }
        
        refreshAccessToken(callback: callback)
    }
    
    func getAccessTokenRefreshParams() -> Requests.Params {
        let data = [Reddit.SYMBOL_GRANT_TYPE: "refresh_token",
                    "refresh_token": refreshToken!]
        
        let username = Reddit.PARAM_CLIENT_ID
        let password = Reddit.SYMBOL_CLIENT_SECRET
        
        let auth = (username: username, password: password)
        let url = URL(string: Reddit.ENDPOINT_ACCESS_TOKEN)!
        
        return (url, data, auth)
    }
    
    func refreshAccessToken(callback: @escaping () -> Void) {
        assert(refreshToken != nil)
        
        let params = getAccessTokenRefreshParams()
        Requests.post(with: params) { (data, response, error) in
            if let response = response as? HTTPURLResponse {
                if 200..<300 ~= response.statusCode { // HTTP OK
                    Util.p("access token refresh: http ok")
                } else {
                    Util.p("access token refresh: http not ok, status code: \(response.statusCode), response", response)
                }
            } else {
                Util.p("access token refresh: something's fucky")
            }
            
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                    Util.p("json", json)
                    
                    let newAccessToken = json["access_token"] as! String
                    let newExpiresIn = json["expires_in"] as! Int
                    
                    self.accessToken = newAccessToken
                    self.accessTokenExpirationDate = Reddit.convertExpiresIn(newExpiresIn)
                    
                    Util.p("access token refresh: all good")
                    Util.p("accesstoken", newAccessToken)
                    Util.p("expiration", self.accessTokenExpirationDate!)
                } catch {
                    Util.p("access token refresh error", error)
                }
            } else if let error = error {
                Util.p("access token refresh error 2", error)
            }
            
            callback()
        }
    }
}
