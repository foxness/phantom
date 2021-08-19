//
//  AboutItemType.swift
//  Phantom
//
//  Created by River on 2021/08/19.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

enum AboutItemType {
    case linkItem(item: LinkAboutItem)
    case textItem(item: TextAboutItem)
}

struct LinkAboutItem {
    let title: String
    let handler: (() -> Void)?
}

struct TextAboutItem {
    let title: String
    let text: String?
    let handler: (() -> Void)?
}
