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
    private static let MENUVIEW_HEIGHT: CGFloat = 320
    private static let FADE_ALPHA: CGFloat = 0.5
    private static let FADE_WHITE: CGFloat = 0.2 // works for both light and dark modes
    private static let ANIMATION_DURATION: TimeInterval = 0.3
    
    private static let TEXT_LOG_IN = "Log In"
    private static let TEXT_LOG_OUT = "Log Out"
    
    weak var delegate: SlideUpMenuDelegate?
    
    private var fadeView: UIView!
    private var menuView: UIView!
    
    private var wallpaperModeSwitch: UISwitch!
    private var redditNameLabel: UILabel!
    private var redditButton: UIButton!
    private var imgurNameLabel: UILabel!
    private var imgurButton: UIButton!
    
    private unowned var window: UIWindow! // I think these should be unowned but I'm not 100% sure
    
    var wallpaperMode = false
    var redditName: String?
    var redditLoggedIn = false
    var imgurName: String?
    var imgurLoggedIn = false
    
    func show() {
        animateShow()
    }
    
    func setupViews(window: UIWindow) {
        self.window = window
        
        setupFadeView()
        setupMenuView()
        
        updateViews()
        prepareToShowViews()
    }
    
    func updateViews() { // todo: separate into 3 and use in didSet of properties?
        wallpaperModeSwitch.isOn = wallpaperMode
        
        redditNameLabel.text = redditName
        
        let redditTitle = redditLoggedIn ? SlideUpMenu.TEXT_LOG_OUT : SlideUpMenu.TEXT_LOG_IN
        redditButton.setTitle(redditTitle, for: .normal)
        
        imgurNameLabel.text = imgurName
        
        let imgurTitle = imgurLoggedIn ? SlideUpMenu.TEXT_LOG_OUT : SlideUpMenu.TEXT_LOG_IN
        imgurButton.setTitle(imgurTitle, for: .normal)
    }
    
    private func setupFadeView() {
        fadeView = UIView()
        fadeView.backgroundColor = UIColor(white: SlideUpMenu.FADE_WHITE, alpha: SlideUpMenu.FADE_ALPHA)
        
        let tapper = UITapGestureRecognizer(target: self, action: #selector(fadeViewTapped))
        fadeView.addGestureRecognizer(tapper)
        
        fadeView.frame = window.frame
    }
    
    private func setupMenuView() {
        menuView = UIView()
        menuView.backgroundColor = UIColor.systemBackground
        
        var constraints = [NSLayoutConstraint]()
        
        // ---------------------------------------------------------------
        
        let bulkAddButton = UIButton()
        bulkAddButton.translatesAutoresizingMaskIntoConstraints = false
        bulkAddButton.setTitle("Bulk Add", for: .normal)
        bulkAddButton.setTitleColor(UIColor.systemBlue, for: .normal)
        bulkAddButton.setTitleColor(UIColor.systemTeal, for: .highlighted)
        bulkAddButton.addTarget(self, action: #selector(bulkAddButtonPressed), for: .touchUpInside)
        menuView.addSubview(bulkAddButton)
        
        menuView.addConstraintsWithFormat(format: "H:|-16-[v0]", views: bulkAddButton)
        menuView.addConstraintsWithFormat(format: "V:|-16-[v0]", views: bulkAddButton)
        
        // ---------------------------------------------------------------
        
        let wallpaperModeLabel = UILabel()
        wallpaperModeLabel.text = "Wallpaper Mode"
        menuView.addSubview(wallpaperModeLabel)
        
        menuView.addConstraintsWithFormat(format: "H:|-16-[v0]", views: wallpaperModeLabel)
        menuView.addConstraintsWithFormat(format: "V:[v0]-16-[v1]", views: bulkAddButton, wallpaperModeLabel)
        
        // ---------------------------------------------------------------
        
        wallpaperModeSwitch = UISwitch()
        wallpaperModeSwitch.translatesAutoresizingMaskIntoConstraints = false
        wallpaperModeSwitch.addTarget(self, action: #selector(wallpaperModeSwitched), for: .valueChanged)
        menuView.addSubview(wallpaperModeSwitch)
        
        constraints += [NSLayoutConstraint(item: wallpaperModeSwitch!, attribute: .leading, relatedBy: .greaterThanOrEqual, toItem: wallpaperModeLabel, attribute: .trailing, multiplier: 1, constant: 16),
                        NSLayoutConstraint(item: wallpaperModeLabel, attribute: .centerY, relatedBy: .equal, toItem: wallpaperModeSwitch, attribute: .centerY, multiplier: 1, constant: 0),
                        NSLayoutConstraint(item: menuView!, attribute: .trailing, relatedBy: .equal, toItem: wallpaperModeSwitch, attribute: .trailing, multiplier: 1, constant: 16)
        ]
        
        // ---------------------------------------------------------------
        
        let redditLabel = UILabel()
        redditLabel.text = "Reddit account"
        menuView.addSubview(redditLabel)
        
        menuView.addConstraintsWithFormat(format: "H:|-16-[v0]", views: redditLabel)
        menuView.addConstraintsWithFormat(format: "V:[v0]-16-[v1]", views: wallpaperModeLabel, redditLabel)
        
        // ---------------------------------------------------------------
        
        redditNameLabel = UILabel()
        menuView.addSubview(redditNameLabel)
        
        menuView.addConstraintsWithFormat(format: "H:|-32-[v0]", views: redditNameLabel)
        menuView.addConstraintsWithFormat(format: "V:[v0]-16-[v1]", views: redditLabel, redditNameLabel)
        
        // ---------------------------------------------------------------
        
        redditButton = UIButton()
        redditButton.translatesAutoresizingMaskIntoConstraints = false
        redditButton.setTitleColor(UIColor.systemBlue, for: .normal)
        redditButton.setTitleColor(UIColor.systemTeal, for: .highlighted)
        redditButton.addTarget(self, action: #selector(redditButtonPressed), for: .touchUpInside)
        menuView.addSubview(redditButton)
        
        constraints += [NSLayoutConstraint(item: redditButton!, attribute: .leading, relatedBy: .greaterThanOrEqual, toItem: redditNameLabel, attribute: .trailing, multiplier: 1, constant: 16),
                        NSLayoutConstraint(item: redditNameLabel!, attribute: .centerY, relatedBy: .equal, toItem: redditButton, attribute: .centerY, multiplier: 1, constant: 0),
                        NSLayoutConstraint(item: menuView!, attribute: .trailing, relatedBy: .equal, toItem: redditButton, attribute: .trailing, multiplier: 1, constant: 16)
        ]
        
        // ---------------------------------------------------------------
        
        let imgurLabel = UILabel()
        imgurLabel.text = "Imgur account"
        menuView.addSubview(imgurLabel)
        
        menuView.addConstraintsWithFormat(format: "H:|-16-[v0]", views: imgurLabel)
        menuView.addConstraintsWithFormat(format: "V:[v0]-16-[v1]", views: redditNameLabel, imgurLabel)
        
        // ---------------------------------------------------------------
        
        imgurNameLabel = UILabel()
        menuView.addSubview(imgurNameLabel)
        
        menuView.addConstraintsWithFormat(format: "H:|-32-[v0]", views: imgurNameLabel)
        menuView.addConstraintsWithFormat(format: "V:[v0]-16-[v1]", views: imgurLabel, imgurNameLabel)
        
        // ---------------------------------------------------------------
        
        imgurButton = UIButton()
        imgurButton.translatesAutoresizingMaskIntoConstraints = false
        imgurButton.setTitleColor(UIColor.systemBlue, for: .normal)
        imgurButton.setTitleColor(UIColor.systemTeal, for: .highlighted)
        imgurButton.addTarget(self, action: #selector(imgurButtonPressed), for: .touchUpInside)
        menuView.addSubview(imgurButton)
        
        constraints += [NSLayoutConstraint(item: imgurButton!, attribute: .leading, relatedBy: .greaterThanOrEqual, toItem: imgurNameLabel, attribute: .trailing, multiplier: 1, constant: 16),
                        NSLayoutConstraint(item: imgurNameLabel!, attribute: .centerY, relatedBy: .equal, toItem: imgurButton, attribute: .centerY, multiplier: 1, constant: 0),
                        NSLayoutConstraint(item: menuView!, attribute: .trailing, relatedBy: .equal, toItem: imgurButton, attribute: .trailing, multiplier: 1, constant: 16)
        ]
        
        // ---------------------------------------------------------------
        
        menuView.addConstraints(constraints)
    }
    
    private func prepareToShowViews() {
        window.addSubview(fadeView)
        window.addSubview(menuView)
        
        hideFadeView()
        hideMenuView()
    }
    
    private func animateShow() {
        let duration = SlideUpMenu.ANIMATION_DURATION
        let delay: TimeInterval = 0
        let options: UIView.AnimationOptions = [.curveEaseOut]
        
        let animations = {
            self.showFadeView()
            self.showMenuView()
        }
        
        UIView.animate(withDuration: duration, delay: delay, options: options, animations: animations, completion: nil)
    }
    
    private func animateHide(onCompleted: (() -> Void)? = nil) {
        let duration = SlideUpMenu.ANIMATION_DURATION
        let delay: TimeInterval = 0
        let options: UIView.AnimationOptions = [.curveEaseOut]
        
        let animations = {
            self.hideFadeView()
            self.hideMenuView()
        }
        
        let completion: (Bool) -> Void = { completed in
            onCompleted?()
        }
        
        UIView.animate(withDuration: duration, delay: delay, options: options, animations: animations, completion: completion)
    }
    
    private func hideFadeView() {
        fadeView.alpha = 0
    }
    
    private func showFadeView() {
        fadeView.alpha = 1
    }
    
    private func hideMenuView() {
        let hiddenMenuFrame = SlideUpMenu.getMenuFrame(hidden: true, windowFrame: window.frame)
        menuView.frame = hiddenMenuFrame
    }
    
    private func showMenuView() {
        let shownMenuFrame = SlideUpMenu.getMenuFrame(hidden: false, windowFrame: window.frame)
        menuView.frame = shownMenuFrame
    }
    
    @objc private func fadeViewTapped() {
        animateHide()
    }
    
    @objc private func redditButtonPressed() {
        if redditLoggedIn {
            delegate?.redditButtonPressed()
        } else {
            animateHide() {
                self.delegate?.redditButtonPressed()
            }
        }
    }
    
    @objc private func imgurButtonPressed() {
        if imgurLoggedIn {
            delegate?.imgurButtonPressed()
        } else {
            animateHide() {
                self.delegate?.imgurButtonPressed()
            }
        }
    }
    
    @objc private func bulkAddButtonPressed() {
        animateHide() {
            self.delegate?.bulkAddButtonPressed()
        }
    }
    
    @objc private func wallpaperModeSwitched(`switch`: UISwitch) {
        let newState = `switch`.isOn
        wallpaperMode = newState
        delegate?.wallpaperModeSwitched(on: newState)
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
