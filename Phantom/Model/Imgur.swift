//
//  Imgur.swift
//  Phantom
//
//  Created by River on 2021/04/28.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

class Imgur {
    // MARK: - Nested entities
    
    struct Image {
        let url: String
        let width: Int
        let height: Int
    }
    
    struct AuthParams: Codable {
        let refreshToken: String
        let accessToken: String
        let accessTokenExpirationDate: Date
        let accountUsername: String
        
        private enum CodingKeys: String, CodingKey {
            case refreshToken, accessToken, accessTokenExpirationDate, accountUsername
        }
    }
    
    struct AuthResponse {
        let state: String
        let error: AuthError?
        let tokenType: String
        let accountId: String
        let accountUsername: String
        let accessToken: String
        let accessTokenExpirationDate: Date
        let refreshToken: String
    }
    
    enum AuthError {
        case accessDenied
        case other(message: String)
    }
    
    enum UserResponse { case none, allow, decline }
    
    // MARK: - Symbols
    
    private struct Symbols {
        static let CLIENT_ID = "client_id"
        static let CLIENT_SECRET = "client_secret"
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
        static let IMAGE = "image"
        static let TYPE = "type"
        static let URL = "url"
        static let DATA = "data"
        static let LINK = "link"
        static let WIDTH = "width"
        static let HEIGHT = "height"
        static let GRANT_TYPE = "grant_type"
    }
    
    // MARK: - Constants
    
    private static let PARAM_CLIENT_ID = "e5a0810d22af4d7"
    private static let PARAM_CLIENT_SECRET = "77f8f3f68d03c4a32f1080e36b658aaf23528159"
    private static let PARAM_REDIRECT_URI = "https://localhost/phantom"
    
    private static let ENDPOINT_AUTH = "https://api.imgur.com/oauth2/authorize"
    private static let ENDPOINT_UPLOAD = "https://api.imgur.com/3/upload"
    private static let ENDPOINT_REFRESH = "https://api.imgur.com/oauth2/token"
    
    // MARK: - Properties
    
    private var authState: String?
    
    private var refreshToken: String?
    private var accessToken: String?
    private var accessTokenExpirationDate: Date?
    
    private var accountUsername: String?
    
    // MARK: - Computed properties
    
    var auth: AuthParams {
        AuthParams(refreshToken: refreshToken!,
                   accessToken: accessToken!,
                   accessTokenExpirationDate: accessTokenExpirationDate!,
                   accountUsername: accountUsername!)
    }
    
    var isLoggedIn: Bool { refreshToken != nil }
    
    // MARK: - Constructors
    
    init() { }
    
    init(auth: AuthParams) {
        self.refreshToken = auth.refreshToken
        self.accessToken = auth.accessToken
        self.accessTokenExpirationDate = auth.accessTokenExpirationDate
        self.accountUsername = auth.accountUsername
    }
    
    // MARK: - Main methods
    
    func uploadImage(imageUrl: URL) throws -> Image { // synchronous
        let request = "imgur upload"
        
        try ensureValidAccessToken()
        
        let params = getUploadImageParams(imageUrl: imageUrl)
        let (data, response, error) = Requests.synchronousPost(with: params)
        
        try Helper.ensureGoodResponse(response: response, request: request)
        try Helper.ensureNoError(error: error, request: request)
        
        let json = try Helper.deserializeResponse(data: data, request: request)
        let imgurImage = try Imgur.deserializeImgurImage(json: json, request: request)
        
        return imgurImage
    }
    
    // MARK: - Auth methods
    
    func getAuthUrl() -> URL {
         // https://api.imgur.com/oauth2/authorize?client_id=YOUR_CLIENT_ID&response_type=REQUESTED_RESPONSE_TYPE&state=APPLICATION_STATE
         
        authState = Helper.getRandomState()
        
        let params = [Symbols.CLIENT_ID: Imgur.PARAM_CLIENT_ID,
                      Symbols.RESPONSE_TYPE: Symbols.TOKEN,
                      Symbols.STATE: authState!]
        
        let url = Helper.appendQuery(url: Imgur.ENDPOINT_AUTH, query: params)
        return url
    }
    
    func getUserResponse(to url: URL) -> UserResponse {
        // https://localhost/phantom?state=asd#access_token=asd&expires_in=123&token_type=bearer&refresh_token=asd&account_username=asd&account_id=123
        
        let fixedUrl = Imgur.getFixedImgurResponse(url: url)
        guard fixedUrl.absoluteString.hasPrefix(Imgur.PARAM_REDIRECT_URI) && authState != nil else { return .none }
        
        let response = try! Imgur.deserializeAuthResponse(url: fixedUrl)
        
        guard response.state == authState else { return .none }
        
        guard response.error == nil else {
            Log.p("imgur auth error", response.error)
            
            return .decline
        }
        
        accountUsername = response.accountUsername
        accessToken = response.accessToken
        accessTokenExpirationDate = response.accessTokenExpirationDate
        refreshToken = response.refreshToken
        
        return .allow
    }
    
    private func refreshAccessToken() throws {
        assert(refreshToken != nil)
        
        let request = "imgur access token refresh"
        
        let params = getAccessTokenRefreshParams()
        let (data, response, error) = Requests.synchronousPost(with: params)
        
        try Helper.ensureGoodResponse(response: response, request: request)
        try Helper.ensureNoError(error: error, request: request)
        
        let json = try Helper.deserializeResponse(data: data, request: request)
        let (newAccessToken, newAccessTokenExpirationDate) = try Imgur.deserializeAccessToken(json: json, request: request)
        
        accessToken = newAccessToken
        accessTokenExpirationDate = newAccessTokenExpirationDate
    }
    
    // MARK: - Deserializer methods
    
    private static func deserializeImgurImage(json: [String: Any], request: String) throws -> Image {
        if let jsonData = json[Symbols.DATA] as? [String: Any],
           let imageUrl = jsonData[Symbols.LINK] as? String,
           let imageWidth = jsonData[Symbols.WIDTH] as? Int,
           let imageHeight = jsonData[Symbols.HEIGHT] as? Int {
            
            let imgurImage = Image(url: imageUrl, width: imageWidth, height: imageHeight)
            return imgurImage
        } else {
            throw ApiError.deserialization(request: request, json: json)
        }
    }
    
    private static func deserializeAccessToken(json: [String: Any], request: String) throws -> (accessToken: String, expirationDate: Date) {
        if let accessToken = json[Symbols.ACCESS_TOKEN] as? String,
           let expiresIn = json[Symbols.EXPIRES_IN] as? Int {
            
            let expirationDate = Helper.convertExpiresIn(expiresIn)
            
            return (accessToken: accessToken, expirationDate: expirationDate)
        } else {
            throw ApiError.deserialization(request: request, json: json)
        }
    }
    
    private static func deserializeAuthResponse(url: URL) throws -> AuthResponse {
        let params = Helper.getQueryItems(url: url)
        
        guard let state = params[Symbols.STATE],
              let tokenType = params[Symbols.TOKEN_TYPE],
              let accountId = params[Symbols.ACCOUNT_ID],
              let expiresInRaw = params[Symbols.EXPIRES_IN],
              let accountUsername = params[Symbols.ACCOUNT_USERNAME],
              let accessToken = params[Symbols.ACCESS_TOKEN],
              let refreshToken = params[Symbols.REFRESH_TOKEN],
              
              tokenType == Symbols.BEARER,
              let expiresIn = Int(expiresInRaw)
        
        else {
            throw ApiError.deserialization(request: "imgur auth url query", json: nil) // todo: send json/string here
        }
        
        let accessTokenExpirationDate = Helper.convertExpiresIn(expiresIn)
        
        let error: AuthError?
        if let rawError = params[Symbols.ERROR] {
            if rawError == Symbols.ACCESS_DENIED {
                error = .accessDenied
            } else {
                error = .other(message: rawError)
            }
        } else {
            error = nil
        }
        
        let response = AuthResponse(state: state,
                                    error: error,
                                    tokenType: tokenType,
                                    accountId: accountId,
                                    accountUsername: accountUsername,
                                    accessToken: accessToken,
                                    accessTokenExpirationDate: accessTokenExpirationDate,
                                    refreshToken: refreshToken)
        return response
    }
    
    // MARK: - Helper methods
    
    private func ensureValidAccessToken() throws {
        guard accessToken == nil ||
                accessTokenExpirationDate == nil ||
                accessTokenExpirationDate! < Date()
        else {
            return
        }
        
        try refreshAccessToken()
    }
    
    private func getUploadImageParams(imageUrl: URL) -> Requests.Params {
        let imageString = imageUrl.absoluteString
        
        let data = [Symbols.IMAGE: imageString,
                    Symbols.TYPE: Symbols.URL]
        
        let username = Symbols.BEARER
        let password = accessToken!
        
        let auth = (username: username, password: password)
        let url = URL(string: Imgur.ENDPOINT_UPLOAD)!
        return (url, data, auth)
    }
    
    private func getAccessTokenRefreshParams() -> Requests.Params {
        let data = [Symbols.REFRESH_TOKEN: refreshToken!,
                    Symbols.CLIENT_ID: Imgur.PARAM_CLIENT_ID,
                    Symbols.CLIENT_SECRET: Imgur.PARAM_CLIENT_SECRET,
                    Symbols.GRANT_TYPE: Symbols.REFRESH_TOKEN]
        
        let auth: (String, String)? = nil
        let url = URL(string: Imgur.ENDPOINT_REFRESH)!
        
        return (url, data, auth)
    }
    
    private static func getFixedImgurResponse(url: URL) -> URL {
        return URL(string: url.absoluteString.replacingOccurrences(of: "#", with: "&"))! // imgur has weird queries
    }
}
