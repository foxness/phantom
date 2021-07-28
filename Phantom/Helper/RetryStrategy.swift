//
//  RetryStrategy.swift
//  Phantom
//
//  Created by River on 2021/05/23.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

enum RetryStrategy {
    case delay(delayRetryStrategy: DelayRetryStrategy)
    case noRetry
}

struct DelayRetryStrategy {
    let maxRetryCount: Int
    let retryInterval: TimeInterval?
}
