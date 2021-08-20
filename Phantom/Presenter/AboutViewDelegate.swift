//
//  AboutViewDelegate.swift
//  Phantom
//
//  Created by River on 2021/08/19.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

protocol AboutViewDelegate: AnyObject {
    func showEmailComposer(to email: String, subject: String?, body: String?)
}
