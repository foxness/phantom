//
//  Helper.swift
//  Phantom
//
//  Created by River on 2021/04/30.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher

struct Helper {
    private static let RANDOM_STATE_LENGTH = 10
    
    private init() { }
    
    static func getQueryItems(url: URL) -> [String: String] {
        let urlc = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let params = urlc.queryItems!.reduce(into: [String:String]()) { $0[$1.name] = $1.value }
        
        return params
    }
    
    static func convertExpiresIn(_ expiresIn: Int) -> Date {
        return Date(timeIntervalSinceNow: TimeInterval(expiresIn))
    }
    
    static func getRandomState(length: Int = RANDOM_STATE_LENGTH) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }
    
    static func toUrlQueryItems(query: [String: String]) -> [URLQueryItem] {
        return query.map { URLQueryItem(name: $0.key, value: $0.value) }
    }
    
    static func appendQuery(url: String, query: [String: String]) -> URL {
        var urlc = URLComponents(string: url)!
        urlc.queryItems = Helper.toUrlQueryItems(query: query)
        return urlc.url!
    }
    
    static func ensureGoodResponse(data: Data?, response: URLResponse?, error: Error?, request: String) throws -> Data {
        guard let response = response, let httpResponse = response as? HTTPURLResponse else {
            throw PhantomError.noResponse(request: request)
        }
        
        if let error = error {
            throw PhantomError.responseHasError(request: request, error: error, data: data, response: httpResponse)
        }
        
        if !Requests.isResponseOk(httpResponse) || data == nil {
            throw PhantomError.badResponse(request: request, response: httpResponse, data: data)
        }
        
        return data!
    }
    
    static func deserializeResponse(data: Data, request: String) throws -> [String: Any] {
        var json: [String: Any]?
        let goodJson: [String: Any]
        do {
            json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            goodJson = json!
        } catch {
            throw PhantomError.deserialization(request: request, raw: String(describing: json))
        }
        
        return goodJson
    }
    
    static func isImageUrl(_ url: String) -> Bool {
        return [".jpg", ".jpeg", ".png"].contains { url.hasSuffix($0) }
    }
    
    static func isValidUrl(_ url: String) -> Bool {
        guard url.hasPrefix("https://") || url.hasPrefix("http://") else { return false }
        
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(location: 0, length: url.utf16.count)
        
        guard let match = detector.firstMatch(in: url, options: [], range: range) else { return false }
        
        return match.range.length == url.utf16.count // it is a link, if the match covers the whole string
    }
    
//    static func isValidUrlForgiving(_ url: String) -> Bool { // forgiving version of isValidUrl()
//        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
//        let range = NSRange(location: 0, length: url.utf16.count)
//
//        guard let match = detector.firstMatch(in: url, options: [], range: range) else { return false }
//
//        return match.range.length == url.utf16.count // it is a link, if the match covers the whole string
//    }
    
//    static func isValidUrl(_ url: String) -> Bool { // this is never used anywhere (yet)
//        guard let url_ = URL(string: url) else { return false }
//
//        return UIApplication.shared.canOpenURL(url_)
//    }
    
    static func extractNamedGroup(_ namedGroup: String, from string: String, using regexes: [String]) -> String? {
        for regex in regexes {
            let re = NSRegularExpression(regex)
            if let match = re.getMatch(string) {
                let range = match.range(withName: namedGroup)
                let extracted = String(string[Range(range, in: string)!])
                
                return extracted
            }
        }
        
        return nil
    }
    
    static func downloadImage(url: URL) throws -> ImageLoadingResult {
        let downloader = ImageDownloader(name: "com.rivershy.Phantom.Helper")
        let options: [KingfisherOptionsInfoItem] = []
        
        var imageDownloadResult: ImageLoadingResult?
        var kfError: KingfisherError?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        downloader.downloadImage(with: url, options: options) { result in
            switch result {
            case .success(let downloadResult):
                imageDownloadResult = downloadResult
            case .failure(let kingfisherError):
                kfError = kingfisherError
            }
            
            semaphore.signal()
        }
        
        semaphore.wait()
        
        if let imageDownloadResult = imageDownloadResult {
            return imageDownloadResult
        } else if let kfError = kfError {
            throw PhantomError.couldntDownloadImage(kfError: kfError)
        }
        
        fatalError("Neither image nor error were found")
    }
    
    static func timeOfDayToDate(_ timeOfDay: TimeInterval) -> Date {
        return Date().startOfDay + timeOfDay
    }
    
    static func dateToTimeOfDay(_ date: Date) -> TimeInterval {
        return date.startOfDay.distance(to: date)
    }
}
