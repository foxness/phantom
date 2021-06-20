//
//  SubmitterMiddleware.swift
//  Phantom
//
//  Created by River on 2021/04/27.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

typealias MiddlewareResult = (mwp: MiddlewarePost, changed: Bool)

protocol SubmitterMiddleware {
    func transform(mwp: MiddlewarePost) throws -> MiddlewareResult
}

struct MiddlewarePost {
    var post: Post
    var imageWidth: Int? = nil
    var imageHeight: Int? = nil
}
