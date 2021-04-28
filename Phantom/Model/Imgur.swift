//
//  Imgur.swift
//  Phantom
//
//  Created by River on 2021/04/28.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

class Imgur {
    private struct Symbols {
        static let CLIENT_ID = "client_id"
        static let RESPONSE_TYPE = "response_type"
        static let TOKEN = "token"
        static let STATE = "state"
//        static let CLIENT_SECRET = ""
//        static let CODE = "code"
//        static let REDIRECT_URI = "redirect_uri"
//        static let DURATION = "duration"
//        static let SCOPE = "scope"
//        static let GRANT_TYPE = "grant_type"
//        static let AUTHORIZATION_CODE = "authorization_code"
//        static let ACCESS_TOKEN = "access_token"
//        static let REFRESH_TOKEN = "refresh_token"
//        static let EXPIRES_IN = "expires_in"
//        static let API_TYPE = "api_type"
//        static let JSON = "json"
//        static let KIND = "kind"
//        static let SELF = "self"
//        static let RESUBMIT = "resubmit"
//        static let SEND_REPLIES = "sendreplies"
//        static let SUBREDDIT = "sr"
//        static let TEXT = "text"
//        static let TITLE = "title"
//        static let BEARER = "bearer"
//        static let DATA = "data"
//        static let URL = "url"
//        static let LINK = "link"
    }
    
    private static let PARAM_CLIENT_ID = "e5a0810d22af4d7"
    private static let PARAM_CLIENT_SECRET = "77f8f3f68d03c4a32f1080e36b658aaf23528159"
    
    private static let ENDPOINT_AUTH = "https://api.imgur.com/oauth2/authorize"
    
    private static let RANDOM_STATE_LENGTH = 10
    
    private var authState: String?
    
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
}
