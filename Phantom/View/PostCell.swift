//
//  PostCell.swift
//  Phantom
//
//  Created by Rivershy on 2020/09/04.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import UIKit
import Kingfisher

// todo: fix thumbnail resolver crashing on unreachable post url "a.com"

class PostCell: UITableViewCell {
    static let IDENTIFIER = "PostCell"
    
    private static let THUMBNAIL_TEXT_POST_PLACEHOLDER = "thumbnail_text_post"
    private static let THUMBNAIL_LINK_POST_PLACEHOLDER = "thumbnail_link_post"
    
    private static let THUMBNAIL_CORNER_RADIUS: CGFloat = 10
    private static let THUMBNAIL_TRANSITION_DURATION: TimeInterval = 0.5
    private static let THUMBNAIL_GUARANTEED_PERIOD: TimeInterval = 3 * 24 * 60 * 60 // expires 3 days after posting
    private static let THUMBNAIL_MAX_PERIOD: TimeInterval = 90 * 24 * 60 * 60 // don't wanna cache for more than 90 days
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var thumbnailView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    
    private let thumbnailResolver: ThumbnailResolver = .instance
    
    private var resolutionTaskId: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setPost(_ post: Post) {
        setMainViews(for: post)
        setThumbnail(for: post)
        setBackground(for: post)
    }
    
    private func setMainViews(for post: Post) {
        let title = post.title
        let subtitle = post.type == .text ? post.text : post.url
        let date = PostCell.dateToString(post.date)
        
        titleLabel.text = title
        subtitleLabel.text = subtitle
        dateLabel.text = date
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
    
    private func setThumbnail(for post: Post, with imageUrl: URL) {
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
    
    private func setBackground(for post: Post) {
        let overdue = post.date < Date()
        let bg: UIColor = overdue ? .secondarySystemBackground : .systemBackground
        contentView.backgroundColor = bg
    }
    
    private func getThumbnailProcessor() -> ImageProcessor {
        let thumbnailSize = thumbnailView.bounds.size
        let processor = AspectCroppingImageProcessor(aspectRatio: thumbnailSize)
            |> DownsamplingImageProcessor(size: thumbnailSize)
            |> RoundCornerImageProcessor(cornerRadius: PostCell.THUMBNAIL_CORNER_RADIUS)
        
        return processor
    }
    
    private static func getScaleFactorOption() -> KingfisherOptionsInfoItem {
        return KingfisherOptionsInfoItem.scaleFactor(UIScreen.main.scale)
    }
    
    private static func dateToString(_ date: Date) -> String { // "in X hours"
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
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
