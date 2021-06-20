//
//  ImgurMiddleware.swift
//  Phantom
//
//  Created by River on 2021/04/28.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation
import Kingfisher
import UIKit

// todo: don't spend time extracting image dimensions if it is false?

struct ImgurMiddleware: SubmitterMiddleware {
    private let imgur: Imgur
    private let directUpload: Bool
    private let extractImageDimensions: Bool
    
    init(_ imgur: Imgur, directUpload: Bool, extractImageDimensions: Bool) {
        self.imgur = imgur
        self.directUpload = directUpload
        self.extractImageDimensions = extractImageDimensions
    }
    
    func transform(mwp: MiddlewarePost) throws -> MiddlewareResult {
        let post = mwp.post
        
        guard ImgurMiddleware.isRightPost(post) else { return (mwp, changed: false) }
        
        let url = URL(string: post.url!)!
        
        let imgurImage: Imgur.Image
        if directUpload {
            Log.p("downloading image...")
            let imageData = try ImgurMiddleware.downloadImage(imageUrl: url)
            Log.p("downloaded!")
            
            Log.p("uploading imgur image directly...")
            imgurImage = try imgur.directlyUploadImage(imageData: imageData)
        } else {
            Log.p("uploading imgur image...")
            imgurImage = try imgur.uploadImage(imageUrl: url)
        }
        
        Log.p("imgur image uploaded", imgurImage)
        
        let newPost = Post.Link(id: post.id,
                                title: post.title,
                                subreddit: post.subreddit,
                                date: post.date,
                                url: imgurImage.url)
        
        var newMwp = MiddlewarePost(post: newPost)
        
        if extractImageDimensions {
            newMwp.imageWidth = imgurImage.width
            newMwp.imageHeight = imgurImage.height
        }
        
        return (newMwp, changed: true)
    }
    
    private static func downloadImage(imageUrl: URL) throws -> Data {
        let downloader = ImageDownloader(name: "com.rivershy.Phantom.ImgurMiddlware()")
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
        
        fatalError("This should be unreachable")
    }
    
    private static func isRightPost(_ post: Post) -> Bool {
        guard post.type == .link, let url = post.url else { return false }
        
        return Helper.isImageUrl(url)
    }
}
