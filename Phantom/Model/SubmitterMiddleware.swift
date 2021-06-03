//
//  SubmitterMiddleware.swift
//  Phantom
//
//  Created by River on 2021/04/27.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

typealias MiddlewareResult = (post: Post, changed: Bool)

protocol SubmitterMiddleware {
    func transform(post: Post) throws -> MiddlewareResult
}
