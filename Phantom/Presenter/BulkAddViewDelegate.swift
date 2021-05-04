//
//  BulkAddViewDelegate.swift
//  Phantom
//
//  Created by River on 2021/05/03.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

protocol BulkAddViewDelegate: AnyObject {
    var postsText: String? { get set }
    
    func setAddButton(enabled: Bool)
    
    func dismiss()
    
    func getClipboard() -> String?
}
