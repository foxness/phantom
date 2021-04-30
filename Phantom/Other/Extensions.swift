//
//  Extensions.swift
//  Phantom
//
//  Created by Rivershy on 2020/08/29.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import Foundation
import UIKit

// todo: use this? https://medium.com/@TomZurkan/creating-an-atomic-property-in-swift-988fa55cc71
final class Atomic<A> { // src: https://www.objc.io/blog/2018/12/18/atomic-variables/
    private let queue = DispatchQueue(label: "Atomic serial queue")
    private var _value: A
    
    init(_ value: A) {
        self._value = value
    }

    var value: A {
        get { queue.sync { self._value } }
    }

    func mutate(_ transform: (inout A) -> ()) {
        queue.sync { transform(&self._value) }
    }
}

extension Sequence {
    func count(`where`: (Element) -> Bool) -> Int {
        return self.lazy.filter(`where`).count
    }
}

extension Array {
    func removed(at indices: [Int]) -> Array {
        return self.indices.filter { !indices.contains($0) }.map { self[$0] }
    }
    
    mutating func remove(at indices: [Int]) {
        self = removed(at: indices)
    }
}

extension Int {
    func times(_ block: @autoclosure () -> Void) {
        guard self > 0 else { return }
        
        for _ in 0..<self {
            block()
        }
    }
    
    func times(_ block: () -> Void) {
        guard self > 0 else { return }
        
        for _ in 0..<self {
            block()
        }
    }
    
    func times(_ block: (Int) -> Void) {
        guard self > 0 else { return }
        
        for i in 0..<self {
            block(i)
        }
    }
}

extension Date {
    static var random: Date { Date(timeIntervalSinceNow: TimeInterval.random(in: 0..<(2 * 24 * 60 * 60))) }
}

extension UIViewController {
    func showToastUnwrapped(_ message: String, seconds: Double = 2) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        
        alert.view.backgroundColor = UIColor.black
        alert.view.alpha = 0.6
        alert.view.layer.cornerRadius = 15
        
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + seconds) {
            alert.dismiss(animated: true)
        }
    }
    
    func showToast(_ message: String, seconds: Double = 2) {
        DispatchQueue.main.async {
            self.showToastUnwrapped(message, seconds: seconds)
        }
    }
}

extension Bundle {
    private static let KEY_RELEASE_VERSION_NUMBER = "CFBundleShortVersionString"
    private static let KEY_BUILD_VERSION_NUMBER = "CFBundleVersion"
    
    var releaseVersionNumber: String { getString(Bundle.KEY_RELEASE_VERSION_NUMBER) }
    var buildVersionNumber: String { getString(Bundle.KEY_BUILD_VERSION_NUMBER) }
    
    private func getString(_ key: String) -> String { infoDictionary?[key] as! String }
}

struct Log {
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
