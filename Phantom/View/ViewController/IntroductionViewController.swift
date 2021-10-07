//
//  IntroductionViewController.swift
//  Phantom
//
//  Created by Rivershy on 2020/08/29.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import UIKit

// todo: add reddit icon into button?
// todo: rename to WelcomeViewController? [ez]

class IntroductionViewController: UIViewController {
    enum Segue: String {
        case showRedditSignIn = "introductionShowRedditSignIn"
    }
    
    private static let BUTTON_CORNER_RADIUS_IOS14: CGFloat = 9
    private static let HIGHLIGHT_TINT_PERCENT_IOS14: CGFloat = 20
    
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var appIconView: UIImageView!
    
    private let hideNavBar = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        styleButtonForIos14()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNavbar(start: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        setNavbar(start: false)
    }
    
    func setNavbar(start: Bool) {
        if hideNavBar {
            navigationController?.navigationBar.isHidden = start
        }
    }
    
    func styleButtonForIos14() {
        if #available(iOS 15.0, *) {
            // intentionally nothing, already styled for iOS 15 in storyboard with iOS 15 filled button style
        } else { // iOS 14
            let tintColor = UIColor(named: "AccentColor")!
            
            signInButton.backgroundColor = tintColor
            signInButton.layer.cornerRadius = IntroductionViewController.BUTTON_CORNER_RADIUS_IOS14
            signInButton.layer.masksToBounds = true
            
            let lighterTint = tintColor.lighter(by: IntroductionViewController.HIGHLIGHT_TINT_PERCENT_IOS14)
            let darkerTint = tintColor.darker(by: IntroductionViewController.HIGHLIGHT_TINT_PERCENT_IOS14)
            let highlightColor = traitCollection.userInterfaceStyle == .dark ? lighterTint : darkerTint

            signInButton.setBackgroundColor(highlightColor, for: .highlighted)
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        styleButtonForIos14()
    }
}

