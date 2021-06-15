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
    // MARK: - Constants
    
    private static let MENU_ITEM_HEIGHT: CGFloat = 50
    private static let MENU_LEEWAY_HEIGHT: CGFloat = 60 // so that the last menu item isn't on the very bottom of the screen
    
    private static let ANIMATION_DURATION: TimeInterval = 0.3
    
    private static let FADE_DARK_MODE_ALPHA: CGFloat = 0.5
    private static let FADE_DARK_MODE_WHITE: CGFloat = 0.2
    
    private static let FADE_LIGHT_MODE_ALPHA: CGFloat = 0.5
    private static let FADE_LIGHT_MODE_WHITE: CGFloat = 0
    
    // MARK: - Views
    
    private var fadeView: UIView!
    private var menuView: UIView!
    private var collectionView: UICollectionView!
    
    // MARK: - Properties
    
    weak var delegate: SlideUpMenuDelegate?
    private var windowFrame: CGRect!
    private var items: [SlideUpMenuItem] = []
    
    // MARK: - Constructors
    
    override init() {
        super.init()
        
        items = getMenuItems()
    }
    
    // MARK: - Menu items
    
    private func getMenuItems() -> [SlideUpMenuItem] {
        return [
            SlideUpMenuItem(title: "Bulk Add", iconSystemName: "plus.app.fill", handler: bulkAddButtonPressed),
            SlideUpMenuItem(title: "Settings", iconSystemName: "gearshape.fill", handler: settingsButtonPressed),
            SlideUpMenuItem(title: "Cancel", iconSystemName: "xmark", handler: cancelButtonPressed)
        ]
    }
    
    // MARK: - Public methods
    
    func show() {
        animateShow()
    }
    
    func setupViews(window: UIWindow) {
        self.windowFrame = window.frame
        
        setupFadeView()
        setupMenuView()
        
        prepareToShowViews(in: window)
    }
    
    // MARK: - View setup methods
    
    private func setupFadeView() {
        fadeView = UIView()
        
        let fadeColorProvider: (UITraitCollection) -> UIColor = { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(white: SlideUpMenu.FADE_DARK_MODE_WHITE, alpha: SlideUpMenu.FADE_DARK_MODE_ALPHA)
            } else {
                return UIColor(white: SlideUpMenu.FADE_LIGHT_MODE_WHITE, alpha: SlideUpMenu.FADE_LIGHT_MODE_ALPHA)
            }
        }
        
        fadeView.backgroundColor = UIColor(dynamicProvider: fadeColorProvider)
        
        let tapper = UITapGestureRecognizer(target: self, action: #selector(fadeViewTapped))
        fadeView.addGestureRecognizer(tapper)
        
        fadeView.frame = windowFrame
    }
    
    private func setupMenuView() {
        menuView = UIView()
        
        let layout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.systemBackground
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(SlideUpMenuCell.self, forCellWithReuseIdentifier: SlideUpMenuCell.IDENTIFIER)
        
        menuView.addSubview(collectionView)
        
        menuView.addConstraintsWithFormat(format: "H:|[v0]|", views: collectionView) // make collectionView take up
        menuView.addConstraintsWithFormat(format: "V:|[v0]|", views: collectionView) // all the space of menuView
    }
    
    private func prepareToShowViews(in window: UIWindow) {
        window.addSubview(fadeView)
        window.addSubview(menuView)
        
        hideFadeView()
        hideMenuView()
    }
    
    // MARK: - Animation methods
    
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
        
        let completion: ((Bool) -> Void)? = onCompleted == nil ? nil : { completed in
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
        menuView.frame = getMenuFrame(hidden: true)
    }
    
    private func showMenuView() {
        menuView.frame = getMenuFrame(hidden: false)
    }
    
    private func getMenuFrame(hidden: Bool) -> CGRect {
        let width: CGFloat = windowFrame.width
        let height: CGFloat = CGFloat(items.count) * SlideUpMenu.MENU_ITEM_HEIGHT + SlideUpMenu.MENU_LEEWAY_HEIGHT
        
        let x: CGFloat = 0
        let y: CGFloat = windowFrame.height - (hidden ? 0 : height)
        
        let menuFrame = CGRect(x: x, y: y, width: width, height: height)
        return menuFrame
    }
    
    // MARK: - User intereaction methods
    
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
    
    // MARK: - Collection View methods
    
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
}
