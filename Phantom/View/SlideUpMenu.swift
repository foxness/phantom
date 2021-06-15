//
//  SlideUpMenu.swift
//  Phantom
//
//  Created by River on 2021/05/06.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation
import UIKit

class SlideUpMenu: NSObject, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    private static let MENU_ITEM_HEIGHT: CGFloat = 50
    private static let MENU_LEEWAY_HEIGHT: CGFloat = 60
    
    private static let ANIMATION_DURATION: TimeInterval = 0.3
    
    private static let FADE_DARK_MODE_ALPHA: CGFloat = 0.5
    private static let FADE_DARK_MODE_WHITE: CGFloat = 0.2
    
    private static let FADE_LIGHT_MODE_ALPHA: CGFloat = 0.5
    private static let FADE_LIGHT_MODE_WHITE: CGFloat = 0
    
    weak var delegate: SlideUpMenuDelegate?
    
    // MARK: - Views
    
    private var fadeView: UIView!
    private var menuView: UIView!
    private var collectionView: UICollectionView!
    
    private unowned var window: UIWindow! // I think these should be unowned but I'm not 100% sure
    
    private var items: [SlideUpMenuItem] = []
    
    override init() {
        super.init()
        
        items = getMenuItems()
    }
    
    private func getMenuItems() -> [SlideUpMenuItem] {
        return [
            SlideUpMenuItem(title: "Bulk Add", iconSystemName: "plus.app.fill", handler: bulkAddButtonPressed),
            SlideUpMenuItem(title: "Settings", iconSystemName: "gearshape.fill", handler: settingsButtonPressed),
            SlideUpMenuItem(title: "Cancel", iconSystemName: "xmark", handler: cancelButtonPressed)
        ]
    }
    
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
        let fadeColorProvider: (UITraitCollection) -> UIColor = { tc in
            if tc.userInterfaceStyle == .dark {
                return UIColor(white: SlideUpMenu.FADE_DARK_MODE_WHITE, alpha: SlideUpMenu.FADE_DARK_MODE_ALPHA)
            } else {
                return UIColor(white: SlideUpMenu.FADE_LIGHT_MODE_WHITE, alpha: SlideUpMenu.FADE_LIGHT_MODE_ALPHA)
            }
        }
        
        fadeView = UIView()
        fadeView.backgroundColor = UIColor(dynamicProvider: fadeColorProvider)
        
        let tapper = UITapGestureRecognizer(target: self, action: #selector(fadeViewTapped))
        fadeView.addGestureRecognizer(tapper)
        
        fadeView.frame = window.frame
    }
    
    private func setupMenuView() {
        menuView = UIView()
//        menuView.backgroundColor = UIColor.systemBackground
        
        let layout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.systemBackground
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(SlideUpMenuCell.self, forCellWithReuseIdentifier: SlideUpMenuCell.IDENTIFIER)
        
        menuView.addSubview(collectionView)
        
        menuView.addConstraintsWithFormat(format: "H:|[v0]|", views: collectionView)
        menuView.addConstraintsWithFormat(format: "V:|[v0]|", views: collectionView)
        
//        // ---------------------------------------------------------------
//
//        let bulkAddButton = UIButton()
//        bulkAddButton.translatesAutoresizingMaskIntoConstraints = false
//        bulkAddButton.setTitle("Bulk Add", for: .normal)
//        bulkAddButton.setTitleColor(UIColor.systemBlue, for: .normal)
//        bulkAddButton.setTitleColor(UIColor.systemTeal, for: .highlighted)
//        bulkAddButton.addTarget(self, action: #selector(bulkAddButtonPressed), for: .touchUpInside)
//        menuView.addSubview(bulkAddButton)
//
//        menuView.addConstraintsWithFormat(format: "H:|-16-[v0]", views: bulkAddButton)
//        menuView.addConstraintsWithFormat(format: "V:|-16-[v0]", views: bulkAddButton)
//
//        // ---------------------------------------------------------------
//
//        let settingsButton = UIButton()
//        settingsButton.translatesAutoresizingMaskIntoConstraints = false
//        settingsButton.setTitle("Settings", for: .normal)
//        settingsButton.setTitleColor(UIColor.systemBlue, for: .normal)
//        settingsButton.setTitleColor(UIColor.systemTeal, for: .highlighted)
//        settingsButton.addTarget(self, action: #selector(settingsButtonPressed), for: .touchUpInside)
//        menuView.addSubview(settingsButton)
//
//        menuView.addConstraintsWithFormat(format: "H:|-16-[v0]", views: settingsButton)
//        menuView.addConstraintsWithFormat(format: "V:[v0]-16-[v1]", views: bulkAddButton, settingsButton)
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
        let hiddenMenuFrame = getMenuFrame(hidden: true, windowFrame: window.frame)
        menuView.frame = hiddenMenuFrame
    }
    
    private func showMenuView() {
        let shownMenuFrame = getMenuFrame(hidden: false, windowFrame: window.frame)
        menuView.frame = shownMenuFrame
    }
    
    @objc private func fadeViewTapped() {
        animateHide()
    }
    
    private func bulkAddButtonPressed() {
        animateHide() {
            self.delegate?.bulkAddButtonPressed()
        }
    }
    
    private func settingsButtonPressed() {
        animateHide() {
            self.delegate?.settingsButtonPressed()
        }
    }
    
    private func cancelButtonPressed() {
        animateHide()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SlideUpMenuCell.IDENTIFIER, for: indexPath) as! SlideUpMenuCell
        
        let item = items[indexPath.item]
        cell.configure(for: item)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 50)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = items[indexPath.item]
        item.handler?()
    }
    
    private func getMenuFrame(hidden: Bool, windowFrame: CGRect) -> CGRect {
        let calculatedHeight = CGFloat(items.count) * SlideUpMenu.MENU_ITEM_HEIGHT + SlideUpMenu.MENU_LEEWAY_HEIGHT
        
        let x: CGFloat = 0
        let y: CGFloat = windowFrame.height - (hidden ? 0 : calculatedHeight)
        let width: CGFloat = windowFrame.width
        let height: CGFloat = calculatedHeight
        
        let menuFrame = CGRect(x: x, y: y, width: width, height: height)
        return menuFrame
    }
}
