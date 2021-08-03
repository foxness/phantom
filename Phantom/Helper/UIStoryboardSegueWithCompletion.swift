//
//  UIStoryboardSegueWithCompletion.swift
//  Phantom
//
//  Created by River on 2021/08/03.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import UIKit

class UIStoryboardSegueWithCompletion: UIStoryboardSegue {
    var completion: (() -> Void)?

    override func perform() {
        super.perform()
        
        if let completion = completion {
            completion()
        }
    }
}
