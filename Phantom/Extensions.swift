//
//  Extensions.swift
//  Phantom
//
//  Created by user179800 on 8/29/20.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation
import UIKit

extension Int {
    var randomString: String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<self).map { _ in letters.randomElement()! })
    }
}

extension Dictionary where Key == String, Value == String {
    var toUrlQueryItems: [URLQueryItem] { map { URLQueryItem(name: $0.key, value: $0.value) } }
}

extension UIViewController {
    func showToast(_ message: String, seconds: Double = 2) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        
        alert.view.backgroundColor = UIColor.black
        alert.view.alpha = 0.6
        alert.view.layer.cornerRadius = 15
        
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + seconds) {
            alert.dismiss(animated: true)
        }
    }
}

struct Util {
    static func dp(_ string: String, _ obj: Any) {
        debugPrint("!!! \(string.uppercased()): \(obj)")
    }
    
    static func dp(_ string: String) {
        debugPrint("!!! \(string.uppercased())")
    }
    
    static func p(_ string: String, _ obj: Any) {
        print("!!! \(string.uppercased()): \(obj)")
    }
    
    static func p(_ string: String) {
        print("!!! \(string.uppercased())")
    }
}
