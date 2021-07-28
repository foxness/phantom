//
//  RedditSignInReceiver.swift
//  Phantom
//
//  Created by River on 2021/06/13.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

protocol RedditSignInReceiver {
    func redditSignedIn(with reddit: Reddit)
}
