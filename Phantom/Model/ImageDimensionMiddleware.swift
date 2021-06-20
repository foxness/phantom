//
//  ImageDimensionMiddleware.swift
//  Phantom
//
//  Created by River on 2021/06/20.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation
import Kingfisher
import UIKit

// todo: do not retry on PhantomError.couldntDownloadImage(kfError: kfError) ?
// todo: refactor downloadImage into helper?

struct ImageDimensionMiddleware: SubmitterMiddleware {
    func transform(mwp: MiddlewarePost) throws -> MiddlewareResult {
        let post = mwp.post
        
        guard ImageDimensionMiddleware.isRightPost(post) else { return (mwp, changed: false) }
        
        let url = URL(string: post.url!)!
        
        Log.p("[ImageDimensionMiddleware] downloading image...")
        let imageData = try ImageDimensionMiddleware.downloadImage(imageUrl: url)
        Log.p("[ImageDimensionMiddleware] downloaded!")
        
        let image = UIImage(data: imageData)!
        let imageWidth = Int(image.size.width)
        let imageHeight = Int(image.size.height)
        
        let newMwp = MiddlewarePost(post: mwp.post, imageWidth: imageWidth, imageHeight: imageHeight)
        return (newMwp, changed: true)
    }
    
    private static func downloadImage(imageUrl: URL) throws -> Data {
        let downloader = ImageDownloader(name: "com.rivershy.Phantom.ImageDimensionMiddleware()")
        let options: [KingfisherOptionsInfoItem] = []
        
        var imageData: Data?
        var kfError: KingfisherError?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        downloader.downloadImage(with: imageUrl, options: options) { result in
            switch result {
            case .success(let downloadResult):
                let origData = downloadResult.originalData
//                let pngData = downloadResult.image.pngData()!
                Log.p("image size: \(origData.count) bytes")
                imageData = origData
            case .failure(let kingfisherError):
                kfError = kingfisherError
            }
            
            semaphore.signal()
        }
        
        semaphore.wait()
        
        if let imageData = imageData {
            assert(!imageData.isEmpty) // todo: throw error if empty? or retry?
            return imageData
        } else if let kfError = kfError {
            throw PhantomError.couldntDownloadImage(kfError: kfError)
        }
        
        fatalError("Neither image data nor error were found")
    }
    
    private static func isRightPost(_ post: Post) -> Bool {
        guard post.type == .link, let url = post.url else { return false }
        
        return Helper.isImageUrl(url)
    }
}
