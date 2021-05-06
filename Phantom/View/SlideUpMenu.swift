//
//  SlideUpMenu.swift
//  Phantom
//
//  Created by River on 2021/05/06.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation
import UIKit

class SlideUpMenu {
    private let blackView = UIView()
    private let menuView = UIView()
    
    private static let MENUVIEW_HEIGHT: CGFloat = 200
    private static let FADE_ALPHA: CGFloat = 0.5
    private static let ANIMATION_DURATION: TimeInterval = 0.5
    
    init() {
        setupViews()
    }
    
    func show() {
        guard let window = SlideUpMenu.getWindow() else { return }
        
        prepareToShowViews(window: window)
        animateShow(window: window)
    }
    
    private func setupViews() {
        setupBlackView()
        setupMenuView()
    }
    
    private func setupBlackView() {
        let white: CGFloat = UIColor.systemBackground == UIColor.white ? 0 : 1
        
        blackView.backgroundColor = UIColor(white: 0.2, alpha: SlideUpMenu.FADE_ALPHA)
        
        let tapper = UITapGestureRecognizer(target: self, action: #selector(blackViewTapped))
        blackView.addGestureRecognizer(tapper)
    }
    
    private func setupMenuView() {
        menuView.backgroundColor = UIColor.systemBackground
    }
    
    private func prepareToShowViews(window: UIWindow) {
        window.addSubview(blackView)
        window.addSubview(menuView)
        
        blackView.frame = window.frame
        blackView.alpha = 0
        
        let x: CGFloat = 0
        let y: CGFloat = window.frame.height
        let width: CGFloat = window.frame.width
        let height: CGFloat = SlideUpMenu.MENUVIEW_HEIGHT
        
        menuView.frame = CGRect(x: x, y: y, width: width, height: height)
    }
    
    private func animateShow(window: UIWindow) {
        let duration = SlideUpMenu.ANIMATION_DURATION
        let delay: TimeInterval = 0
        let options: UIView.AnimationOptions = [.curveEaseOut]
        
        let animations = {
            self.blackView.alpha = 1
            
            let x: CGFloat = 0
            let y: CGFloat = window.frame.height - SlideUpMenu.MENUVIEW_HEIGHT
            let width: CGFloat = self.menuView.frame.width
            let height: CGFloat = self.menuView.frame.height
            
            self.menuView.frame = CGRect(x: x, y: y, width: width, height: height)
        }
        
        let completion = { (completed: Bool) in
            
        }
        
        UIView.animate(withDuration: duration, delay: delay, options: options, animations: animations, completion: completion)
    }
    
    private func animateHide(window: UIWindow) {
        let duration = SlideUpMenu.ANIMATION_DURATION
        let delay: TimeInterval = 0
        let options: UIView.AnimationOptions = [.curveEaseOut]
        
        let animations = {
            self.blackView.alpha = 0
            
            let x: CGFloat = 0
            let y: CGFloat = window.frame.height
            let width: CGFloat = window.frame.width
            let height: CGFloat = SlideUpMenu.MENUVIEW_HEIGHT
            
            self.menuView.frame = CGRect(x: x, y: y, width: width, height: height)
        }
        
        let completion = { (completed: Bool) in
            
        }
        
        UIView.animate(withDuration: duration, delay: delay, options: options, animations: animations, completion: completion)
    }
    
    @objc private func blackViewTapped() {
        guard let window = SlideUpMenu.getWindow() else { return }
        
        animateHide(window: window)
    }
    
    private static func getWindow() -> UIWindow? {
        return UIApplication.shared.windows.first(where: { $0.isKeyWindow })
    }
}
