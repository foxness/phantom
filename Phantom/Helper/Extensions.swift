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

extension UIButton {
    // source: https://stackoverflow.com/a/27095410
    private func imageWithColor(_ color: UIColor) -> UIImage? {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()

        context?.setFillColor(color.cgColor)
        context?.fill(rect)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }

    func setBackgroundColor(_ color: UIColor, for state: UIControl.State) {
        setBackgroundImage(imageWithColor(color), for: state)
    }
}

extension UITableView {
    // source: https://stackoverflow.com/a/45157417
    
    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height))
        messageLabel.text = message
        messageLabel.textColor = .secondaryLabel
//        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        
        // if you don't set the font, the default font is System (San Francisco UI) 17pt
//        messageLabel.font = UIFont(name: "TrebuchetMS", size: 15)
        
//        messageLabel.sizeToFit()

        backgroundView = messageLabel
//        separatorStyle = .none
    }

    func removeEmptyMessage() {
        backgroundView = nil
//        separatorStyle = .singleLine
    }
}

extension UITableView { // CURRENTLY UNUSED ---------------------------------------------------------------
    // UITableView.showLeadingSwipeHintGlitched() and UITableViewCell.showLeadingSwipeHintGlitched() are currently
    // unused because I'm using a glitchless version that only works with a custom view hierarchy
    // but I'm leaving these here because they might prove useful later.
    // This non-custom version is able to be glitched if you time your swipe just right at the start of the animation
    
    /**
     Shows a hint to the user indicating that the cell can be swiped right.
     - Parameters:
        - width: Width of hint.
        - duration: Duration of animation (in seconds)
     
     This is a modified version of [this guy's answer](https://stackoverflow.com/a/63000276)
     */
    func showLeadingSwipeHintGlitched(width: CGFloat = 20, duration: TimeInterval = 0.8, cornerRadius: CGFloat? = nil) {
        guard let (cell, actionColor) = getLeadingSwipeHintCell() else { return }
        
        cell.showLeadingSwipeHintGlitched(actionColor: actionColor, width: width, duration: duration, cornerRadius: cornerRadius)
    }
    
    func getLeadingSwipeHintCell() -> (cell: UITableViewCell, actionColor: UIColor)? {
        var cellPath: IndexPath?
        var actionColor: UIColor?
        
        guard let visibleIndexPaths = indexPathsForVisibleRows else { return nil }
        
        for path in visibleIndexPaths {
            if let config = delegate?.tableView?(self, leadingSwipeActionsConfigurationForRowAt: path),
               let action = config.actions.first {
                
                cellPath = path
                actionColor = action.backgroundColor
                
                break
            }
        }
        
        guard let path = cellPath, let cell = cellForRow(at: path) else { return nil }
        
        return (cell: cell, actionColor: actionColor!)
    }
}

fileprivate extension UITableViewCell {
    func showLeadingSwipeHintGlitched(actionColor: UIColor, width: CGFloat = 20, duration: TimeInterval = 0.8, cornerRadius: CGFloat? = nil) {
        // appealing curve sets: --------------------------------------------
        // - [.easeIn, .easeOut]
        // - [.easeOut, .easeIn]
        // - [.easeInOut, .easeInOut]
        
        let curves: [UIView.AnimationCurve] = [.easeInOut, .easeInOut]
        
        // ------------------------------------------------------------------
        
        let originalClipsToBounds = clipsToBounds
        let originalCornerRadius = contentView.layer.cornerRadius
        
        let cornerRadiusBuffer = cornerRadius ?? 0
        
        let dummyView = UIView()
        dummyView.backgroundColor = actionColor
        dummyView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(dummyView, belowSubview: contentView)
        
        NSLayoutConstraint.activate([
            dummyView.topAnchor.constraint(equalTo: topAnchor),
            dummyView.trailingAnchor.constraint(equalTo: leadingAnchor, constant: cornerRadiusBuffer),
            dummyView.bottomAnchor.constraint(equalTo: bottomAnchor),
            dummyView.widthAnchor.constraint(equalToConstant: width + cornerRadiusBuffer)
        ])
        
        // Animates restoration back to the original state
        let secondAnimator = UIViewPropertyAnimator(duration: duration / 2, curve: curves[1]) {
            self.transform = .identity
            
            if cornerRadius != nil {
                self.contentView.layer.cornerRadius = originalCornerRadius
            }
        }
        
        secondAnimator.addCompletion { position in
            dummyView.removeFromSuperview()
            self.clipsToBounds = originalClipsToBounds
        }
        
        // Animates showing hint
        let firstAnimator = UIViewPropertyAnimator(duration: duration / 2, curve: curves[0]) {
            self.transform = CGAffineTransform(translationX: width, y: 0)
            
            if let cornerRadius = cornerRadius {
                self.contentView.layer.cornerRadius = cornerRadius
            }
            
            self.clipsToBounds = false // so that it doesn't clip the dummyView which is out of bounds
        }
        
        firstAnimator.addCompletion { position in
            secondAnimator.startAnimation()
        }
        
        firstAnimator.startAnimation()
    }
}

extension UIColor {
    // source: https://stackoverflow.com/a/42381754
    
    /**
     Create a lighter color
     */
    func lighter(by percentage: CGFloat = 30) -> UIColor {
        return adjustBrightness(by: abs(percentage))
    }
    
    /**
     Create a darker color
     */
    func darker(by percentage: CGFloat = 30) -> UIColor {
        return adjustBrightness(by: -abs(percentage))
    }
    
    /**
     Try to increase brightness or decrease saturation
     */
    func adjustBrightness(by percentage: CGFloat = 30) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        
        if getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            if b < 1.0 {
                let newB: CGFloat = max(min(b + (percentage / 100.0) * b, 1.0), 0.0)
                return UIColor(hue: h, saturation: s, brightness: newB, alpha: a)
            } else {
                let newS: CGFloat = min(max(s - (percentage / 100.0) * s, 0.0), 1.0)
                return UIColor(hue: h, saturation: newS, brightness: b, alpha: a)
            }
        }
        
        return self
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
