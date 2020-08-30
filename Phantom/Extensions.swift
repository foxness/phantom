//
//  Extensions.swift
//  Phantom
//
//  Created by user179800 on 8/29/20.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation

extension Int {
    var randomString: String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<self).map { _ in letters.randomElement()! })
    }
}

extension Dictionary where Key == String, Value == String {
    var toUrlQueryItems: [URLQueryItem] { map { URLQueryItem(name: $0.key, value: $0.value) } }
}

struct Util {
    static func p(_ string: String, _ obj: Any) {
        print("!!! \(string.uppercased()): \(obj)")
    }
    
    static func p(_ string: String) {
        print("!!! \(string.uppercased())")
    }
}
