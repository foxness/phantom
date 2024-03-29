//
//  PostCell.swift
//  Phantom
//
//  Created by Rivershy on 2020/09/04.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import UIKit
import Kingfisher

class PostCell: UITableViewCell {
    static let IDENTIFIER = "PostCell"
    
    private static let THUMBNAIL_TEXT_POST_PLACEHOLDER = "thumbnail_text_post"
    private static let THUMBNAIL_LINK_POST_PLACEHOLDER = "thumbnail_link_post"
    
    private static let THUMBNAIL_CORNER_RADIUS: CGFloat = 10
    private static let THUMBNAIL_TRANSITION_DURATION: TimeInterval = 0.5
    private static let THUMBNAIL_GUARANTEED_PERIOD: TimeInterval = 3 * 24 * 60 * 60 // expires 3 days after posting
    private static let THUMBNAIL_MAX_PERIOD: TimeInterval = 90 * 24 * 60 * 60 // don't wanna cache for more than 90 days
    
    
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var thumbnailView: UIImageView!
    
    private let thumbnailResolver: ThumbnailResolver = .instance
    
    private var resolutionTaskId: String?
    
    func setPost(_ post: Post) {
        setMainViews(for: post)
        setThumbnail(for: post)
        setBackground(for: post)
    }
    
    private func setMainViews(for post: Post) {
        let title = post.title
        
        let date = PostCell.dateToString(post.date)
        let subtitle = "/r/\(post.subreddit) • \(date)"
        
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }
    
    private func setThumbnail(for post: Post) {
        thumbnailView.kf.cancelDownloadTask()
        
        guard post.type == .link, let postUrl = post.url else {
            setPlaceholder(for: post)
            return
        }
        
        if thumbnailResolver.isCached(url: postUrl) {
            let thumbnailUrl = thumbnailResolver.getCached(key: postUrl)
            forceSetThumbnail(for: post, thumbnailUrl: thumbnailUrl)
        } else {
            setThumbnailForUncachedLinkPost(post)
        }
    }
    
    private func setThumbnailForUncachedLinkPost(_ post: Post) {
        setPlaceholder(for: post) // set placeholder while we're waiting. it doesn't have kf-style animations but still
        
        let postUrl = post.url!
        
        // taskId is to ensure it is still the same post cell when the thumbnail is resolved
        // the post cell might be hosting a different post if the user is scrolling fast
        let taskId = post.id.uuidString // I this I can also make it Helper.getRandomState()
        resolutionTaskId = taskId
        thumbnailResolver.resolveThumbnailUrl(with: postUrl) { [weak self] thumbnailUrl in
            guard let self = self, self.resolutionTaskId == taskId else {
                self?.thumbnailResolver.removeCached(url: postUrl) // I'm like 99% sure this won't result in a deadlock
                return
            }
            
            self.resolutionTaskId = nil
            
            DispatchQueue.main.async {
                self.forceSetThumbnail(for: post, thumbnailUrl: thumbnailUrl)
            }
        }
    }
    
    private func forceSetThumbnail(for post: Post, thumbnailUrl: String?) {
        if let thumbnailUrl = thumbnailUrl, let url = URL(string: thumbnailUrl) {
            self.setThumbnail(for: post, with: url)
        } else {
            self.setPlaceholder(for: post)
        }
    }
    
    private func setThumbnail(for post: Post, with imageUrl: URL) { // todo: rounded corner by imageview not the image itself
        let placeholder = getPlaceholder(for: post.type)
        let transition = ImageTransition.flipFromRight(PostCell.THUMBNAIL_TRANSITION_DURATION)
        let thumbnailExpiration = StorageExpiration.date(PostCell.getThumbnailExpirationDate(postDate: post.date))
        let processor = getThumbnailProcessor()
        let cacheSerializer = FormatIndicatedCacheSerializer.png // png because we need transparency because rounded corners are transparent
        let scaleFactorOption = PostCell.getScaleFactorOption()
        
        let options: KingfisherOptionsInfo = [
            .processor(processor),
            .cacheSerializer(cacheSerializer),
            .transition(transition),
            .diskCacheExpiration(thumbnailExpiration),
            scaleFactorOption
//            ,.forceRefresh
        ]
        
        thumbnailView.kf.indicatorType = .activity
        thumbnailView.kf.setImage(with: imageUrl, placeholder: placeholder, options: options)
    }
    
    private func setPlaceholder(for post: Post) {
        let placeholder = getPlaceholder(for: post.type)
        thumbnailView.image = placeholder
    }
    
    private func getPlaceholder(for type: Post.PostType) -> UIImage {
        let name: String
        switch type {
        case .text:
            name = PostCell.THUMBNAIL_TEXT_POST_PLACEHOLDER
        case .link:
            name = PostCell.THUMBNAIL_LINK_POST_PLACEHOLDER
        }
        
        let placeholder = ImageProcessItem.image(UIImage(named: name)!)
        let options = KingfisherParsedOptionsInfo([PostCell.getScaleFactorOption()])
        let processor = getThumbnailProcessor()
        let processedPlaceholder = processor.process(item: placeholder, options: options)!
        
        return processedPlaceholder
    }
    
    private func setBackground(for post: Post) { // todo: use prepareForReuse() instead
        let overdue = post.date < Date()
        let bg: UIColor = overdue ? .secondarySystemBackground : .systemBackground
        bgView.backgroundColor = bg
    }
    
    private func getThumbnailProcessor() -> ImageProcessor {
        let thumbnailSize = thumbnailView.bounds.size
        let processor = AspectCroppingImageProcessor(aspectRatio: thumbnailSize)
            |> DownsamplingImageProcessor(size: thumbnailSize)
            |> RoundCornerImageProcessor(cornerRadius: PostCell.THUMBNAIL_CORNER_RADIUS)
        
        return processor
    }
    
    func showLeadingSwipeHint(actionColor: UIColor, width: CGFloat = 20, duration: TimeInterval = 0.8, cornerRadius: CGFloat? = nil) {
        // appealing curve sets: --------------------------------------------
        // - [.easeIn, .easeOut]
        // - [.easeOut, .easeIn]
        // - [.easeInOut, .easeInOut]
        
        let curves: [UIView.AnimationCurve] = [.easeInOut, .easeInOut]
        
        // ------------------------------------------------------------------
        
        let originalCornerRadius = bgView.layer.cornerRadius
        
        let dummyView = UIView()
        dummyView.backgroundColor = actionColor
        dummyView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.insertSubview(dummyView, belowSubview: bgView)
        
        NSLayoutConstraint.activate([
            dummyView.topAnchor.constraint(equalTo: contentView.topAnchor),
            dummyView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            dummyView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            dummyView.widthAnchor.constraint(equalToConstant: width + (cornerRadius ?? 0))
        ])
        
        // Animates restoration back to the original state
        let secondAnimator = UIViewPropertyAnimator(duration: duration / 2, curve: curves[1]) { [self] in
            bgView.transform = .identity
            
            if cornerRadius != nil {
                bgView.layer.cornerRadius = originalCornerRadius
            }
        }
        
        secondAnimator.addCompletion { position in
            dummyView.removeFromSuperview()
        }
        
        // Animates showing hint
        let firstAnimator = UIViewPropertyAnimator(duration: duration / 2, curve: curves[0]) { [self] in
            bgView.transform = CGAffineTransform(translationX: width, y: 0)
            
            if let cornerRadius = cornerRadius {
                bgView.layer.cornerRadius = cornerRadius
            }
        }
        
        firstAnimator.addCompletion { position in
            secondAnimator.startAnimation()
        }
        
        firstAnimator.startAnimation()
    }
    
    private static func getScaleFactorOption() -> KingfisherOptionsInfoItem {
        return KingfisherOptionsInfoItem.scaleFactor(UIScreen.main.scale)
    }
    
    private static func dateToString(_ date: Date) -> String { // example: "in 2 hours"
        let now = Date() // todo: refactor into Helper
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.dateTimeStyle = .numeric
        return formatter.localizedString(for: date, relativeTo: now)
    }
    
    private static func getThumbnailExpirationDate(postDate: Date) -> Date {
        let now = Date()
        if postDate < now { // post is in the past
            return now + PostCell.THUMBNAIL_GUARANTEED_PERIOD // 3 days from now
        } else { // post is in the future
            let expireDate = postDate + PostCell.THUMBNAIL_GUARANTEED_PERIOD // 3 days after post
            let maxDate = now + PostCell.THUMBNAIL_MAX_PERIOD // 90 days from now
            
            return expireDate > maxDate ? maxDate : expireDate
        }
    }
}

struct AspectCroppingImageProcessor: ImageProcessor {
    let identifier: String
    let aspectRatio: CGSize
    
    init(aspectRatio: CGSize = CGSize(width: 1, height: 1)) { // default is square aspect ratio
        self.aspectRatio = aspectRatio
        self.identifier = "com.rivershy.AspectCroppingImageProcessor(\(String(describing: self.aspectRatio)))"
    }
    
    func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        switch item {
        case .image(let image):
            return AspectCroppingImageProcessor.aspectCrop(image: image, aspectRatio: aspectRatio)
        case .data(_):
            return (DefaultImageProcessor.default |> self).process(item: item, options: options)
        }
    }
    
    private static func aspectCrop(image: UIImage, aspectRatio: CGSize) -> UIImage {
        let imageHeight = image.size.height
        let imageWidth = image.size.width
        
        let imageAspectRatio = imageWidth / imageHeight
        let targetAspectRatio = aspectRatio.width / aspectRatio.height
        
        let resultWidth: CGFloat
        let resultHeight: CGFloat
        if imageAspectRatio > targetAspectRatio {
            // image is wider than target
            
            // ratio = width / height
            // width = ratio * height
            // height = width / ratio
            
            resultHeight = imageHeight
            resultWidth = resultHeight * targetAspectRatio
        } else {
            // target is wider than image
            
            resultWidth = imageWidth
            resultHeight = resultWidth / targetAspectRatio
        }
        
        let resultSize = CGSize(width: resultWidth, height: resultHeight)
        let centerPoint = CGPoint(x: 0.5, y: 0.5)
        let resultImage = image.kf.crop(to: resultSize, anchorOn: centerPoint)
        
        return resultImage
    }
}
