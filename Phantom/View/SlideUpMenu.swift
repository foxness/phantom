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
    private static let MENUVIEW_HEIGHT: CGFloat = 200
    private static let FADE_ALPHA: CGFloat = 0.5
    private static let ANIMATION_DURATION: TimeInterval = 0.5
    
    private var blackView: UIView!
    private var menuView: UIView!
    
    private var window: UIWindow!
    
    private var onRedditLogout: (() -> Void)?
    
    func show() {
        animateShow()
    }
    
    func setupViews(window: UIWindow, onRedditLogout: (() -> Void)? = nil) {
        self.onRedditLogout = onRedditLogout
        self.window = window
        
        setupBlackView()
        setupMenuView()
        
        prepareToShowViews()
    }
    
    private func setupBlackView() {
        blackView = UIView()
        blackView.backgroundColor = UIColor(white: 0.2, alpha: SlideUpMenu.FADE_ALPHA) // works for both light and dark modes
        
        let tapper = UITapGestureRecognizer(target: self, action: #selector(blackViewTapped))
        blackView.addGestureRecognizer(tapper)
    }
    
    private func setupMenuView() {
        menuView = UIView()
        menuView.backgroundColor = UIColor.systemBackground
        
        let redditLabel = UILabel()
        redditLabel.text = "Reddit account"
        menuView.addSubview(redditLabel)
        
        menuView.addConstraintsWithFormat(format: "H:|-16-[v0]", views: redditLabel)
        menuView.addConstraintsWithFormat(format: "V:|-16-[v0]", views: redditLabel)
        
        let redditNameLabel = UILabel()
        redditNameLabel.text = "redditName"
        menuView.addSubview(redditNameLabel)
        
        menuView.addConstraintsWithFormat(format: "H:|-32-[v0]", views: redditNameLabel)
        menuView.addConstraintsWithFormat(format: "V:[v0]-16-[v1]", views: redditLabel, redditNameLabel)
        
        let redditLogoutButton = UIButton()
        redditLogoutButton.translatesAutoresizingMaskIntoConstraints = false
        redditLogoutButton.setTitle("Log out", for: .normal)
        redditLogoutButton.setTitleColor(UIColor.systemBlue, for: .normal)
        redditLogoutButton.setTitleColor(UIColor.systemTeal, for: .highlighted)
        redditLogoutButton.addTarget(self, action: #selector(redditLogoutButtonPressed), for: .touchUpInside)
        menuView.addSubview(redditLogoutButton)
        
        let constraints = [NSLayoutConstraint(item: redditLogoutButton, attribute: .leading, relatedBy: .greaterThanOrEqual, toItem: redditNameLabel, attribute: .trailing, multiplier: 1, constant: 16),
                           NSLayoutConstraint(item: redditNameLabel, attribute: .centerY, relatedBy: .equal, toItem: redditLogoutButton, attribute: .centerY, multiplier: 1, constant: 0),
                           NSLayoutConstraint(item: menuView, attribute: .trailing, relatedBy: .equal, toItem: redditLogoutButton, attribute: .trailing, multiplier: 1, constant: 16)
        ]
        
        menuView.addConstraints(constraints)
    }
    
    private func prepareToShowViews() {
        window.addSubview(blackView)
        window.addSubview(menuView)
        
        blackView.frame = window.frame
        
        hideBlackView()
        hideMenuView()
    }
    
    private func animateShow() {
        let duration = SlideUpMenu.ANIMATION_DURATION
        let delay: TimeInterval = 0
        let options: UIView.AnimationOptions = [.curveEaseOut]
        
        let animations = {
            self.showBlackView()
            self.showMenuView()
        }
        
        let completion = { (completed: Bool) in
            // todo: remove this?
        }
        
        UIView.animate(withDuration: duration, delay: delay, options: options, animations: animations, completion: completion)
    }
    
    private func animateHide(onCompleted: (() -> Void)? = nil) {
        let duration = SlideUpMenu.ANIMATION_DURATION
        let delay: TimeInterval = 0
        let options: UIView.AnimationOptions = [.curveEaseOut]
        
        let animations = {
            self.hideBlackView()
            self.hideMenuView()
        }
        
        let completion: (Bool) -> Void = { completed in
            onCompleted?()
        }
        
        UIView.animate(withDuration: duration, delay: delay, options: options, animations: animations, completion: completion)
    }
    
    private func hideBlackView() {
        blackView.alpha = 0
    }
    
    private func showBlackView() {
        blackView.alpha = 1
    }
    
    private func hideMenuView() {
        let hiddenMenuFrame = SlideUpMenu.getMenuFrame(hidden: true, windowFrame: self.window.frame)
        menuView.frame = hiddenMenuFrame
    }
    
    private func showMenuView() {
        let shownMenuFrame = SlideUpMenu.getMenuFrame(hidden: false, windowFrame: self.window.frame)
        menuView.frame = shownMenuFrame
    }
    
    @objc private func blackViewTapped() {
        animateHide()
    }
    
    @objc private func redditLogoutButtonPressed() {
        animateHide() {
            self.onRedditLogout?()
        }
    }
    
    private static func getMenuFrame(hidden: Bool, windowFrame: CGRect) -> CGRect {
        let x: CGFloat = 0
        let y: CGFloat = windowFrame.height - (hidden ? 0 : SlideUpMenu.MENUVIEW_HEIGHT)
        let width: CGFloat = windowFrame.width
        let height: CGFloat = SlideUpMenu.MENUVIEW_HEIGHT
        
        let menuFrame = CGRect(x: x, y: y, width: width, height: height)
        return menuFrame
    }
}
