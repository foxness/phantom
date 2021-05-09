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
    private var redditNameLabel: UILabel!
    private var redditButton: UIButton!
    
    private var window: UIWindow!
    
    var onRedditButtonPressed: (() -> Void)?
    
    var redditName: String? = "redditName"
    var redditLoggedIn = true
    
    func show() {
        animateShow()
    }
    
    func setupViews(window: UIWindow) {
        self.window = window
        
        setupBlackView()
        setupMenuView()
        
        updateViews()
        prepareToShowViews()
    }
    
    func updateViews() {
        redditNameLabel.text = redditName
        
        let title = redditLoggedIn ? "Log Out" : "Log In"
        redditButton.setTitle(title, for: .normal)
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
        
        redditNameLabel = UILabel()
        menuView.addSubview(redditNameLabel)
        
        menuView.addConstraintsWithFormat(format: "H:|-32-[v0]", views: redditNameLabel)
        menuView.addConstraintsWithFormat(format: "V:[v0]-16-[v1]", views: redditLabel, redditNameLabel)
        
        redditButton = UIButton()
        redditButton.translatesAutoresizingMaskIntoConstraints = false
        redditButton.setTitleColor(UIColor.systemBlue, for: .normal)
        redditButton.setTitleColor(UIColor.systemTeal, for: .highlighted)
        redditButton.addTarget(self, action: #selector(redditButtonPressed), for: .touchUpInside)
        menuView.addSubview(redditButton)
        
        let constraints = [NSLayoutConstraint(item: redditButton, attribute: .leading, relatedBy: .greaterThanOrEqual, toItem: redditNameLabel, attribute: .trailing, multiplier: 1, constant: 16),
                           NSLayoutConstraint(item: redditNameLabel, attribute: .centerY, relatedBy: .equal, toItem: redditButton, attribute: .centerY, multiplier: 1, constant: 0),
                           NSLayoutConstraint(item: menuView, attribute: .trailing, relatedBy: .equal, toItem: redditButton, attribute: .trailing, multiplier: 1, constant: 16)
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
    
    @objc private func redditButtonPressed() {
        if redditLoggedIn {
            onRedditButtonPressed?()
        } else {
            animateHide() {
                self.onRedditButtonPressed?()
            }
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
