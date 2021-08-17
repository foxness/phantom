//
//  AboutViewController.swift
//  Phantom
//
//  Created by River on 2021/08/16.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController {
    @IBOutlet weak var appIconView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tintAppIcon()
    }
    
    func tintAppIcon() {
        appIconView.makeTintable()
        
        // uncomment for black&white icon
//        appIconView.tintColor = UIColor.label
    }
}
