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
        let username: String
        
        private enum CodingKeys: String, CodingKey {
            case refreshToken, accessToken, accessTokenExpirationDate, username
        }
    }
    
    struct AuthResponse {
        let state: String
        let error: AuthError?
        let tokenType: String
        let accountId: String
        let username: String
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
        static let BASE64 = "base64"
    }
    
    // MARK: - Constants
    
    private static let ENDPOINT_AUTH = "https://api.imgur.com/oauth2/authorize"
    private static let ENDPOINT_UPLOAD = "https://api.imgur.com/3/upload"
    private static let ENDPOINT_REFRESH = "https://api.imgur.com/oauth2/token"
    
    // MARK: - Properties
    
    private let clientId: String
    private let clientSecret: String
    private let redirectUri: String
    
    private var authState: String?
    
    private var refreshToken: String?
    private var accessToken: String?
    private var accessTokenExpirationDate: Date?
    
    private(set) var username: String?
    
    // MARK: - Computed properties
    
    var auth: AuthParams? {
        guard isSignedIn else { return nil }
        
        return AuthParams(refreshToken: refreshToken!,
                          accessToken: accessToken!,
                          accessTokenExpirationDate: accessTokenExpirationDate!,
                          username: username!)
    }
    
    var isSignedIn: Bool { refreshToken != nil }
    
    // MARK: - Constructors
    
    init(clientId: String, clientSecret: String, redirectUri: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.redirectUri = redirectUri
    }
    
    convenience init(clientId: String, clientSecret: String, redirectUri: String, auth: AuthParams) {
        self.init(clientId: clientId, clientSecret: clientSecret, redirectUri: redirectUri)
        
        self.refreshToken = auth.refreshToken
        self.accessToken = auth.accessToken
        self.accessTokenExpirationDate = auth.accessTokenExpirationDate
        self.username = auth.username
    }
    
    // MARK: - Main methods
    
    func uploadImage(imageUrl: URL) throws -> Image { // synchronous
        assert(isSignedIn) // todo: throw error instead
        
        let request = "imgur upload"
        
        try ensureValidAccessToken()
        
        let params = getUploadImageParams(imageUrl: imageUrl)
        let (data, response, error) = Requests.postSync(with: params)
        
        let goodData = try Helper.ensureGoodResponse(data: data, response: response, error: error, request: request)
        let json = try Helper.deserializeResponse(data: goodData, request: request)
        let imgurImage = try Imgur.deserializeImgurImage(json: json, request: request)
        
        return imgurImage
    }
    
    func directlyUploadImage(imageData: Data) throws -> Image {
        assert(isSignedIn)
        
        let request = "imgur upload direct"
        
        try ensureValidAccessToken()
        
        let params = getDirectImageUploadParams(imageData: imageData)
        let (data, response, error) = Requests.postSync(with: params)
        
        let goodData = try Helper.ensureGoodResponse(data: data, response: response, error: error, request: request)
        let json = try Helper.deserializeResponse(data: goodData, request: request)
        let imgurImage = try Imgur.deserializeImgurImage(json: json, request: request)
        
        return imgurImage
    }
    
    // MARK: - Auth methods
    
    func getAuthUrl() -> URL {
         // https://api.imgur.com/oauth2/authorize?client_id=YOUR_CLIENT_ID&response_type=REQUESTED_RESPONSE_TYPE&state=APPLICATION_STATE
         
        authState = Helper.getRandomState()
        
        let params = [Symbols.CLIENT_ID: clientId,
                      Symbols.RESPONSE_TYPE: Symbols.TOKEN,
                      Symbols.STATE: authState!]
        
        let url = Helper.appendQuery(url: Imgur.ENDPOINT_AUTH, query: params)
        return url
    }
    
    func getUserResponse(to url: URL) -> UserResponse {
        // https://localhost/phantom?state=asd#access_token=asd&expires_in=123&token_type=bearer&refresh_token=asd&account_username=asd&account_id=123
        
        let fixedUrl = Imgur.getFixedImgurResponse(url: url)
        guard fixedUrl.absoluteString.hasPrefix(redirectUri) && authState != nil else { return .none }
        
        let response = try! Imgur.deserializeAuthResponse(url: fixedUrl)
        
        guard response.state == authState else { return .none }
        
        guard response.error == nil else {
            Log.p("imgur auth error", response.error)
            
            return .decline
        }
        
        username = response.username
        accessToken = response.accessToken
        accessTokenExpirationDate = response.accessTokenExpirationDate
        refreshToken = response.refreshToken
        
        return .allow
    }
    
    private func refreshAccessToken() throws {
        assert(isSignedIn)
        
        let request = "imgur access token refresh"
        
        let params = getAccessTokenRefreshParams()
        let (data, response, error) = Requests.postSync(with: params)
        
        let goodData = try Helper.ensureGoodResponse(data: data, response: response, error: error, request: request)
        let json = try Helper.deserializeResponse(data: goodData, request: request)
        let (newAccessToken, newAccessTokenExpirationDate) = try Imgur.deserializeAccessToken(json: json, request: request)
        
        accessToken = newAccessToken
        accessTokenExpirationDate = newAccessTokenExpirationDate
    }
    
    func logout() {
        assert(isSignedIn)
        
        username = nil
        refreshToken = nil
        accessToken = nil
        accessTokenExpirationDate = nil
    }
    
    // MARK: - Deserializer methods
    
    private static func deserializeImgurImage(json: [String: Any], request: String) throws -> Image {
        guard let jsonData = json[Symbols.DATA] as? [String: Any],
              let imageUrl = jsonData[Symbols.LINK] as? String,
              let imageWidth = jsonData[Symbols.WIDTH] as? Int,
              let imageHeight = jsonData[Symbols.HEIGHT] as? Int
        else {
            throw PhantomError.deserialization(request: request, raw: String(describing: json))
        }
            
        let imgurImage = Image(url: imageUrl, width: imageWidth, height: imageHeight)
        return imgurImage
    }
    
    private static func deserializeAccessToken(json: [String: Any], request: String) throws -> (accessToken: String, expirationDate: Date) {
        guard let accessToken = json[Symbols.ACCESS_TOKEN] as? String,
           let expiresIn = json[Symbols.EXPIRES_IN] as? Int
        else {
            throw PhantomError.deserialization(request: request, raw: String(describing: json))
        }
            
        let expirationDate = Helper.convertExpiresIn(expiresIn)
        return (accessToken: accessToken, expirationDate: expirationDate)
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
            throw PhantomError.deserialization(request: "imgur auth url query", raw: String(describing: params))
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
                                    username: accountUsername,
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
    
    private func getUploadImageParams(imageUrl: URL) -> Requests.PostParams {
        let imageString = imageUrl.absoluteString
        
        let dataDict = [Symbols.IMAGE: imageString,
                        Symbols.TYPE: Symbols.URL]
        
        let data = Requests.getDataParams(dataDict: dataDict)
        
        let auth = getBearerAuth()
        let url = getUploadEndpoint()
        
        return (url, data, auth)
    }
    
    private func getDirectImageUploadParams(imageData: Data) -> Requests.PostParams {
        let imageString = imageData.base64EncodedString()
        
        let dataDict = [Symbols.IMAGE: imageString,
                        Symbols.TYPE: Symbols.BASE64]
        
        let data = Requests.getDataParams(dataDict: dataDict, dataType: .multipartFormData)
        
        let auth = getBearerAuth()
        let url = getUploadEndpoint()
        return (url, data, auth)
    }
    
    private func getAccessTokenRefreshParams() -> Requests.PostParams {
        let dataDict = [Symbols.REFRESH_TOKEN: refreshToken!,
                        Symbols.CLIENT_ID: clientId,
                        Symbols.CLIENT_SECRET: clientSecret,
                        Symbols.GRANT_TYPE: Symbols.REFRESH_TOKEN]
        
        let data = Requests.getDataParams(dataDict: dataDict)
        
        let auth: Requests.AuthParams? = nil
        let url = URL(string: Imgur.ENDPOINT_REFRESH)!
        
        return (url, data, auth)
    }
    
    private func getUploadEndpoint() -> URL {
        return URL(string: Imgur.ENDPOINT_UPLOAD)!
    }
    
    private func getBearerAuth() -> Requests.AuthParams {
        return Requests.getAuthParams(username: Symbols.BEARER, password: accessToken!)
    }
    
    private static func getFixedImgurResponse(url: URL) -> URL {
        return URL(string: url.absoluteString.replacingOccurrences(of: "#", with: "&"))! // imgur has weird queries
    }
    
    // MARK: - Thumbnail calculator methods
    
    static func calculateThumbnailUrl(from imgurUrl: String) -> String? {
        let imgurIdGroup = "imgurId"
        let thumbnailSize = "m" // there's "s", "m", and "l"
        
        // indirect example: https://imgur.com/NeGReDX
        // indirect regex: https://imgur\.com/(?<imgurId>\w+)
        
        let indirectRegex = "https://imgur\\.com/(?<\(imgurIdGroup)>\\w+)"
        
        // direct example: https://i.imgur.com/NeGReDX.png
        // direct regex: https://i\.imgur\.com/(?<imgurId>\w+)\.\w+
        
        let directRegex = "https://i\\.imgur\\.com/(?<\(imgurIdGroup)>\\w+)\\.\\w+"
        
        let regexes = [indirectRegex, directRegex]
        guard let imgurId = Helper.extractNamedGroup(imgurIdGroup, from: imgurUrl, using: regexes) else { return nil }
        
        let thumbnailUrl = "https://i.imgur.com/\(imgurId)\(thumbnailSize).jpg"
        return thumbnailUrl
    }
}
