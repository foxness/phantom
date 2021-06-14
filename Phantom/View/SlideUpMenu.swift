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
    private static let MENUVIEW_HEIGHT: CGFloat = 180
    private static let FADE_ALPHA: CGFloat = 0.6
    private static let FADE_WHITE: CGFloat = 0 // works for both light and dark modes
    private static let ANIMATION_DURATION: TimeInterval = 0.3
    
    weak var delegate: SlideUpMenuDelegate?
    
    // MARK: - Views
    
    private var fadeView: UIView!
    private var menuView: UIView!
    
    private unowned var window: UIWindow! // I think these should be unowned but I'm not 100% sure
    
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
    
    func updateViews() {
        
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
        
        let settingsButton = UIButton()
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.setTitle("Settings", for: .normal)
        settingsButton.setTitleColor(UIColor.systemBlue, for: .normal)
        settingsButton.setTitleColor(UIColor.systemTeal, for: .highlighted)
        settingsButton.addTarget(self, action: #selector(settingsButtonPressed), for: .touchUpInside)
        menuView.addSubview(settingsButton)
        
        menuView.addConstraintsWithFormat(format: "H:|-16-[v0]", views: settingsButton)
        menuView.addConstraintsWithFormat(format: "V:[v0]-16-[v1]", views: bulkAddButton, settingsButton)
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
    
    @objc private func bulkAddButtonPressed() {
        animateHide() {
            self.delegate?.bulkAddButtonPressed()
        }
    }
    
    @objc private func settingsButtonPressed() {
        animateHide() {
            self.delegate?.settingsButtonPressed()
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
