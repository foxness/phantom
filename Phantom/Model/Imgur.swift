//
//  Imgur.swift
//  Phantom
//
//  Created by River on 2021/04/28.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

class Imgur { // todo: add OAuthAPI superclass that Reddit and Imgur inherit from to reduce helper method duplication
    struct AuthParams: Codable {
        let refreshToken: String
        let accessToken: String
        let accessTokenExpirationDate: Date
        let accountUsername: String
        
        private enum CodingKeys: String, CodingKey {
            case refreshToken, accessToken, accessTokenExpirationDate, accountUsername
        }
    }
    
    enum UserResponse { case none, allow, decline }
    
    private struct Symbols {
        static let CLIENT_ID = "client_id"
        static let RESPONSE_TYPE = "response_type"
        static let TOKEN = "token"
        static let STATE = "state"
        static let ACCESS_TOKEN = "access_token"
        static let REFRESH_TOKEN = "refresh_token"
        static let EXPIRES_IN = "expires_in"
        static let TOKEN_TYPE = "token_type"
        static let BEARER = "bearer"
        static let ACCOUNT_USERNAME = "account_username"
        static let ACCOUNT_ID = "account_id"
        static let ERROR = "error"
        static let ACCESS_DENIED = "access_denied"
//        static let CLIENT_SECRET = ""
//        static let CODE = "code"
//        static let REDIRECT_URI = "redirect_uri"
//        static let DURATION = "duration"
//        static let SCOPE = "scope"
//        static let GRANT_TYPE = "grant_type"
//        static let AUTHORIZATION_CODE = "authorization_code"
//        static let API_TYPE = "api_type"
//        static let JSON = "json"
//        static let KIND = "kind"
//        static let SELF = "self"
//        static let RESUBMIT = "resubmit"
//        static let SEND_REPLIES = "sendreplies"
//        static let SUBREDDIT = "sr"
//        static let TEXT = "text"
//        static let TITLE = "title"
//        static let DATA = "data"
//        static let URL = "url"
//        static let LINK = "link"
    }
    
    private static let PARAM_CLIENT_ID = "e5a0810d22af4d7"
    private static let PARAM_CLIENT_SECRET = "77f8f3f68d03c4a32f1080e36b658aaf23528159"
    private static let PARAM_REDIRECT_URI = "https://localhost/phantom"
    
    private static let ENDPOINT_AUTH = "https://api.imgur.com/oauth2/authorize"
    
    private static let RANDOM_STATE_LENGTH = 10
    
    private var authState: String?
    
    private var refreshToken: String?
    private var accessToken: String?
    private var accessTokenExpirationDate: Date?
    
    private var accountUsername: String?
    
    var auth: AuthParams {
        AuthParams(refreshToken: refreshToken!,
                   accessToken: accessToken!,
                   accessTokenExpirationDate: accessTokenExpirationDate!,
                   accountUsername: accountUsername!)
    }
    
    var isLoggedIn: Bool { refreshToken != nil }
    
    init() { }
    
    init(auth: AuthParams) {
        self.refreshToken = auth.refreshToken
        self.accessToken = auth.accessToken
        self.accessTokenExpirationDate = auth.accessTokenExpirationDate
        self.accountUsername = auth.accountUsername
    }
    
    func getAuthUrl() -> URL {
         // https://api.imgur.com/oauth2/authorize?client_id=YOUR_CLIENT_ID&response_type=REQUESTED_RESPONSE_TYPE&state=APPLICATION_STATE
         
        authState = Imgur.getRandomState()
        
        let params = [Symbols.CLIENT_ID: Imgur.PARAM_CLIENT_ID,
                      Symbols.RESPONSE_TYPE: Symbols.TOKEN,
                      Symbols.STATE: authState!]
        
        var urlc = URLComponents(string: Imgur.ENDPOINT_AUTH)!
        urlc.queryItems = params.toUrlQueryItems
        return urlc.url!
    }
    
    private static func getRandomState() -> String { Imgur.RANDOM_STATE_LENGTH.randomString }
    
    func getUserResponse(to url: URL) -> UserResponse {
        // https://localhost/phantom?state=eNpSdAay6g#access_token=4968d4d34a027c825ce93bb7a6885394ad868c15&expires_in=315360000&token_type=bearer&refresh_token=d183f67f5d3d3e894f00b46ed2751421a2a892b7&account_username=nymphadriel&account_id=72892655
        
        let fixedUrl = URL(string: url.absoluteString.replacingOccurrences(of: "#", with: "&"))! // imgur has weird queries
        guard fixedUrl.absoluteString.hasPrefix(Imgur.PARAM_REDIRECT_URI) && authState != nil else { return .none }
        
        let urlc = URLComponents(url: fixedUrl, resolvingAgainstBaseURL: false)!
        let params = urlc.queryItems!.reduce(into: [String:String]()) { $0[$1.name] = $1.value }
        
        let state = params[Symbols.STATE]
        guard state != nil && state == authState else { return .none }
        
        let error = params[Symbols.ERROR]
        guard error == nil else {
            let error2 = error!
            if error2 == Symbols.ACCESS_DENIED {
                Log.p("imgur auth denied by user")
            } else {
                Log.p("imgur auth error", error2)
            }
            
            return .decline
        }
        
        let tokenType = params[Symbols.TOKEN_TYPE]
        let accountId = params[Symbols.ACCOUNT_ID]
        let expiresIn = params[Symbols.EXPIRES_IN]
        accountUsername = params[Symbols.ACCOUNT_USERNAME]
        
        accessToken = params[Symbols.ACCESS_TOKEN]
        accessTokenExpirationDate = Imgur.convertExpiresIn(Int(expiresIn!)!)
        refreshToken = params[Symbols.REFRESH_TOKEN]
        
        guard tokenType == Symbols.BEARER,
              accountId != nil,
              accountUsername != nil,
              accessToken != nil,
              refreshToken != nil
        else {
            fatalError("Imgur API might have changed or something")
        }
        
        return .allow
    }
    
    private static func convertExpiresIn(_ expiresIn: Int) -> Date {
        return Date(timeIntervalSinceNow: TimeInterval(expiresIn))
    }
}
