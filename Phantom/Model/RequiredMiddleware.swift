//
//  RequiredMiddleware.swift
//  Phantom
//
//  Created by River on 2021/05/23.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

struct RequiredMiddleware: SubmitterMiddleware {
    let middleware: SubmitterMiddleware
    let isRequired: Bool
    
    func transform(mwp: MiddlewarePost) throws -> MiddlewareResult {
        return try middleware.transform(mwp: mwp)
    }
}
