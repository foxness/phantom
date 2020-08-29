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

struct Reddit {
    enum UserResponse { case none, allow, decline }
    
    static let AUTH_CLIENT_ID = "XTWjw2332iSmmQ"
    static let AUTH_RESPONSE_TYPE = "code"
    static let AUTH_REDIRECT_URI = "https://localhost/phantomdev"
    static let AUTH_DURATION = "permanent"
    static let AUTH_SCOPE = "identity submit"
    
    static let AUTHORIZE_ENDPOINT = "https://www.reddit.com/api/v1/authorize.compact"
    static let ACCESS_TOKEN_ENDPOINT = "https://www.reddit.com/api/v1/access_token"
    
    static let RANDOM_STATE_LENGTH = 10
    
    var authState: String?
    var authCode: String?
    
    var randomState: String { Reddit.RANDOM_STATE_LENGTH.randomString }
    
    mutating func getAuthUrl() -> URL {
         // https://www.reddit.com/api/v1/authorize?client_id=CLIENT_ID&response_type=TYPE&state=RANDOM_STRING&redirect_uri=URI&duration=DURATION&scope=SCOPE_STRING
         
        authState = randomState
        
        let params = ["client_id": Reddit.AUTH_CLIENT_ID,
                      "response_type": Reddit.AUTH_RESPONSE_TYPE,
                      "state": authState!,
                      "redirect_uri": Reddit.AUTH_REDIRECT_URI,
                      "duration": Reddit.AUTH_DURATION,
                      "scope": Reddit.AUTH_SCOPE]
        
        var urlc = URLComponents(string: Reddit.AUTHORIZE_ENDPOINT)!
        urlc.queryItems = params.toUrlQueryItems
        return urlc.url!
    }
    
    mutating func getUserResponse(to url: URL) -> UserResponse {
        guard url.absoluteString.hasPrefix(Reddit.AUTH_REDIRECT_URI) && authState != nil else { return .none }
        
        let urlc = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let params = urlc.queryItems!.reduce(into: [String:String]()) { $0[$1.name] = $1.value }
        
        let state = params["state"]
        guard state != nil && state == authState else { return .none }
        
        authState = nil
        authCode = params["code"]
        return authCode == nil ? .decline : .allow
    }
    
    mutating func fetchAuthTokens() {
        assert(authCode != nil)
        
        let params = ["grant_type": "authorization_code",
                      "code": authCode!,
                      "redirect_uri": Reddit.AUTH_REDIRECT_URI]
        
        let username = Reddit.AUTH_CLIENT_ID
        let password = ""
        
        let auth = (username: username, password: password)
        
        Requests.post(to: URL(string: Reddit.ACCESS_TOKEN_ENDPOINT)!, with: params, auth: auth) { (data, response, error) in
            if let response = response {
                Util.p("response", response)
            }
            
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    Util.p("json", json)
                } catch {
                    Util.p("error", error)
                }
            }
        }
    }
}
