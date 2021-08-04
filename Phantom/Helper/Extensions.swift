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
        queue.sync { self._value }
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
//    static var random: Date { Date(timeIntervalSinceNow: TimeInterval.random(in: 0..<(2 * 24 * 60 * 60))) }
    
    var startOfDay: Date {
        let calendar = Calendar.current
        
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: self)
        let dayStart = calendar.date(from: dateComponents)!
        
        return dayStart
    }
}

extension UIViewController {
    func showToastUnwrapped(_ message: String, seconds: Double = 2) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        
        alert.view.backgroundColor = UIColor.black
        alert.view.alpha = 0.6
        alert.view.layer.cornerRadius = 15
        
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            alert.dismiss(animated: true)
        }
    }
    
    func showToast(_ message: String, seconds: Double = 2) {
        DispatchQueue.main.async {
            self.showToastUnwrapped(message, seconds: seconds)
        }
    }
    
    func displayOkAlert(title: String, message: String?, dismissHandler: (() -> Void)? = nil) {
        let handler = { (action: UIAlertAction) -> Void in
            dismissHandler?()
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.view.tintColor = view.tintColor
        
        let action = UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: handler)
        alert.addAction(action)
        
        present(alert, animated: true, completion: nil)
    }
}

extension Bundle {
    private static let KEY_RELEASE_VERSION_NUMBER = "CFBundleShortVersionString"
    private static let KEY_BUILD_VERSION_NUMBER = "CFBundleVersion"
    
    var releaseVersionNumber: String { getString(Bundle.KEY_RELEASE_VERSION_NUMBER) }
    var buildVersionNumber: String { getString(Bundle.KEY_BUILD_VERSION_NUMBER) }
    
    private func getString(_ key: String) -> String { infoDictionary?[key] as! String }
}

// src: https://www.hackingwithswift.com/articles/108/how-to-use-regular-expressions-in-swift
extension NSRegularExpression {
    convenience init(_ pattern: String) {
        do {
            try self.init(pattern: pattern)
        } catch {
            preconditionFailure("Illegal regular expression: \(pattern)")
        }
    }
    
    func getMatch(_ string: String) -> NSTextCheckingResult? {
        let range = NSRange(location: 0, length: string.utf16.count)
        let match = firstMatch(in: string, options: [], range: range)
        return match
    }
    
    func matches(_ string: String) -> Bool {
        return getMatch(string) != nil
    }
}

// src: https://www.hackingwithswift.com/articles/108/how-to-use-regular-expressions-in-swift
extension String {
    func matchesRegex(_ regex: String) throws -> Bool {
        let re = try NSRegularExpression(pattern: regex)
        let matches = re.matches(self)
        return matches
    }
    
    static func ~= (lhs: String, rhs: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: rhs) else { return false }
        let matches = regex.matches(lhs)
        return matches
    }
    
    func findMiddleKey(startKey: String, endKey: String) -> String? {
        guard let start = self.range(of: startKey)?.upperBound,
              let end = self.range(of: endKey, options: [], range: start..<self.endIndex , locale: nil)?.lowerBound
        else {
            return nil
        }
        
        let found = String(self[start..<end])
        return found
    }
    
    func trim() -> String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension UIView {
    func addConstraintsWithFormat(format: String, views: UIView...) {
        var viewsDict = [String: UIView]()
        
        for (index, view) in views.enumerated() {
            let key = "v\(index)"
            view.translatesAutoresizingMaskIntoConstraints = false
            viewsDict[key] = view
        }
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options: [], metrics: nil, views: viewsDict))
    }
}

extension UITableView {
    /**
     Shows a hint to the user indicating that the cell can be swiped right.
     - Parameters:
        - width: Width of hint.
        - duration: Duration of animation (in seconds)
     
     This is a modified version of [this guy's answer](https://stackoverflow.com/a/63000276)
     */
    func showLeadingSwipeHint(width: CGFloat = 20, duration: TimeInterval = 0.8) {
        var cellPath: IndexPath?
        var actionColor: UIColor?
        
        guard let visibleIndexPaths = indexPathsForVisibleRows else { return }
        
        for path in visibleIndexPaths {
            if let config = delegate?.tableView?(self, leadingSwipeActionsConfigurationForRowAt: path),
               let action = config.actions.first {
                
                cellPath = path
                actionColor = action.backgroundColor
                
                break
            }
        }
        
        guard let path = cellPath, let cell = cellForRow(at: path) else { return }
        
        cell.showLeadingSwipeHint(actionColor: actionColor!, hintWidth: width, hintDuration: duration)
    }
}

fileprivate extension UITableViewCell {
    func showLeadingSwipeHint(actionColor: UIColor, hintWidth: CGFloat = 20, hintDuration: TimeInterval = 0.8) {
        let originalClipsToBounds = clipsToBounds
        
        let dummyView = UIView()
        dummyView.backgroundColor = actionColor
        dummyView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dummyView)
        
        NSLayoutConstraint.activate([
            dummyView.topAnchor.constraint(equalTo: topAnchor),
            dummyView.trailingAnchor.constraint(equalTo: leadingAnchor),
            dummyView.bottomAnchor.constraint(equalTo: bottomAnchor),
            dummyView.widthAnchor.constraint(equalToConstant: hintWidth)
        ])
        
        // Animates restoration back to the original state
        let secondAnimator = UIViewPropertyAnimator(duration: hintDuration / 2, curve: .easeOut) {
            self.transform = .identity
        }
        
        secondAnimator.addCompletion { position in
            dummyView.removeFromSuperview()
            self.clipsToBounds = originalClipsToBounds
        }
        
        // Animates showing hint
        let firstAnimator = UIViewPropertyAnimator(duration: hintDuration / 2, curve: .easeIn) {
            self.transform = CGAffineTransform(translationX: hintWidth, y: 0)
            self.clipsToBounds = false // so that it doesn't clip the dummyView which is out of bounds
        }
        
        firstAnimator.addCompletion { position in
            secondAnimator.startAnimation()
        }
        
        firstAnimator.startAnimation()
    }
}

//extension LocalizedError where Self: CustomStringConvertible {
//   var errorDescription: String? { description }
//}

struct Log {
//    static func dp(_ string: String, _ obj: Any) {
//        debugPrint("!!! \(string.uppercased()): \(obj)")
//    }
//
//    static func dp(_ string: String) {
//        debugPrint("!!! \(string.uppercased())")
//    }
    
    static func p(_ string: String, _ obj: Any) {
        print("!!! \(string.uppercased()): \(String(reflecting: obj))")
    }
    
    static func p(_ string: String) {
        print("!!! \(string.uppercased())")
    }
}