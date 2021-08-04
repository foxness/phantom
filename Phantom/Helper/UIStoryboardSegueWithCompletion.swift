//
//  UIStoryboardSegueWithCompletion.swift
//  Phantom
//
//  Created by River on 2021/08/03.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import UIKit

// source: https://stackoverflow.com/questions/27483881/perform-push-segue-after-an-unwind-segue

class UIStoryboardSegueWithCompletion: UIStoryboardSegue {
    var completion: (() -> Void)?

    override func perform() {
        super.perform()
        
        completion?()
    }
}
