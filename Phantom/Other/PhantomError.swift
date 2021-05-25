//
//  PhantomError.swift
//  Phantom
//
//  Created by River on 2021/05/18.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation
import Kingfisher

enum PhantomError: LocalizedError, CustomDebugStringConvertible {
    case responseHasError(request: String, error: Error, data: Data?, response: HTTPURLResponse?)
    case badResponse(request: String, response: HTTPURLResponse, data: Data?)
    case deserialization(request: String, raw: String)
    case requiredMiddlewareNoEffect(middleware: String)
    case couldntDownloadImage(kfError: KingfisherError)
    
//    var errorDescription: String?
//    var failureReason: String?
//    var recoverySuggestion: String?
//    var helpAnchor: String?
    
    var errorDescription: String? {
        switch self {
        case .responseHasError(let request, let error, let data, let response):
            return "An error occurred during \(request): \(error.localizedDescription)"
        case .badResponse(let request, let response, let data):
            let dataString = PhantomError.getDataString(data: data)
            return "An error occurred during \(request): \(dataString)"
        case .deserialization(let request, let raw):
            return "An error occurred during \(request): unable to deserialize the response: \(raw.prefix(30))..."
        case .requiredMiddlewareNoEffect(let middleware):
            return "Required middleware \(middleware) had no effect"
        case .couldntDownloadImage(let kfError):
            return "Couldn't download image: \(kfError.localizedDescription)"
        }
    }
    
    var debugDescription: String {
        switch self {
        case .responseHasError(let request, let error, let data, let response):
            return "PhantomError.responseHasError(request: \(String(reflecting: request)), error: \(String(reflecting: error)), data: \(String(reflecting: data)), response: \(String(reflecting: response))) Error Localized Description: \(error.localizedDescription); Data String: \(PhantomError.getDataString(data: data))"
        case .badResponse(let request, let response, let data):
            return "PhantomError.badResponse(request: \(String(reflecting: request)), response: \(String(reflecting: response)), data: \(String(reflecting: data))) Data String: \(PhantomError.getDataString(data: data))"
        case .deserialization(let request, let raw):
            return "PhantomError.deserialization(request: \(String(reflecting: request)), raw: \(String(reflecting: raw)))"
        case .requiredMiddlewareNoEffect(let middleware):
            return "PhantomError.requiredMiddlewareNoEffect(middleware: \(String(describing: middleware)))"
        case .couldntDownloadImage(let kfError):
            return "PhantomError.couldntDownloadImage(kfError: \(String(reflecting: kfError)))"
        }
    }
    
    private static func getDataString(data: Data?) -> String {
        let dataString: String
        if let data = data {
            if let decoded = String(data: data, encoding: .utf8) {
                dataString = decoded
            } else {
                dataString = String(describing: data)
            }
        } else {
            dataString = "nil"
        }
        
        return dataString
    }
}
