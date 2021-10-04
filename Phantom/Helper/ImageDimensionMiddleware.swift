//
//  ImageDimensionMiddleware.swift
//  Phantom
//
//  Created by River on 2021/06/20.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

// todo: do not retry on PhantomError.couldntDownloadImage(kfError: kfError) ?

struct ImageDimensionMiddleware: SubmitterMiddleware {
    func transform(mwp: MiddlewarePost) throws -> MiddlewareResult {
        let post = mwp.post
        
        guard ImageDimensionMiddleware.isRightPost(post) else { return (mwp, changed: false) }
        
        let url = URL(string: post.url!)!
        
        Log.p("[ImageDimensionMiddleware] downloading image...")
        let imageDownloadResult = try Helper.downloadImage(url: url)
        Log.p("[ImageDimensionMiddleware] downloaded!")
        
        let imageWidth = Int(imageDownloadResult.image.size.width)
        let imageHeight = Int(imageDownloadResult.image.size.height)
        
        let newMwp = MiddlewarePost(post: mwp.post, imageWidth: imageWidth, imageHeight: imageHeight)
        return (newMwp, changed: true)
    }
    
    private static func isRightPost(_ post: Post) -> Bool {
        return Helper.isImagePost(post)
    }
}
