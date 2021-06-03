//
//  IntroductionViewController.swift
//  Phantom
//
//  Created by Rivershy on 2020/08/29.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import UIKit

class IntroductionViewController: UIViewController {
    enum Segue: String {
        case showLogin = "showLogin"
    }
    
    private let hideNavBar = true

    override func viewDidLoad() {
        super.viewDidLoad()
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
}

