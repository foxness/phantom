//
//  IntroductionViewController.swift
//  Phantom
//
//  Created by Rivershy on 2020/08/29.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import UIKit

// todo: add reddit icon into button?
// todo: add real app icon
// todo: better fonts
// todo: better spacing
// todo: rename to WelcomeViewController? [ez]

class IntroductionViewController: UIViewController {
    enum Segue: String {
        case showRedditSignIn = "introductionShowRedditSignIn"
    }
    
    private static let BUTTON_CORNER_RADIUS: CGFloat = 9
    
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var appIconView: UIImageView!
    
    private let hideNavBar = true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        roundButtonCorners()
        tintAppIcon()
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
    
    func roundButtonCorners() {
        signInButton.layer.cornerRadius = IntroductionViewController.BUTTON_CORNER_RADIUS
        signInButton.layer.masksToBounds = true
    }
    
    func tintAppIcon() {
        appIconView.image = appIconView.image?.withRenderingMode(.alwaysTemplate)
        
        // uncomment for black&white icon
//        appIconView.tintColor = UIColor.label
    }
}

