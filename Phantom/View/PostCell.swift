//
//  PostCell.swift
//  Phantom
//
//  Created by Rivershy on 2020/09/04.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import UIKit
import Kingfisher

// todo: add custom kingfisher image cache to avoid calculating wallhaven & imgur thumbnail urls?

class PostCell: UITableViewCell {
    static let IDENTIFIER = "PostCell"
    
    private static let THUMBNAIL_TEXT_POST_PLACEHOLDER = "thumbnail_text_post"
    private static let THUMBNAIL_CORNER_RADIUS: CGFloat = 10
    private static let THUMBNAIL_TRANSITION_DURATION: TimeInterval = 0.5
    private static let THUMBNAIL_GUARANTEED_PERIOD: TimeInterval = 3 * 24 * 60 * 60 // expires 3 days after posting
    private static let THUMBNAIL_MAX_PERIOD: TimeInterval = 90 * 24 * 60 * 60 // don't wanna cache for more than 90 days
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var thumbnailView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    
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
        if let imageUrl = PostCell.getThumbnailUrl(from: post) {
            setThumbnail(for: post, with: imageUrl)
        } else {
            setPlaceholder(for: post)
        }
    }
    
    private func setThumbnail(for post: Post, with imageUrl: URL) {
        let placeholder = PostCell.getPlaceholder(for: post.type)
        let transition = ImageTransition.flipFromRight(PostCell.THUMBNAIL_TRANSITION_DURATION)
        let thumbnailExpirationDate = PostCell.getThumbnailExpirationDate(postDate: post.date)
        
        let thumbnailSize = thumbnailView.bounds.size
        let processor = AspectCroppingImageProcessor(aspectRatio: thumbnailSize)
            |> DownsamplingImageProcessor(size: thumbnailSize)
            |> RoundCornerImageProcessor(cornerRadius: PostCell.THUMBNAIL_CORNER_RADIUS)
        
        let options: KingfisherOptionsInfo = [
            .processor(processor),
            
            // png because we need transparency because rounded corners are transparent
            .cacheSerializer(FormatIndicatedCacheSerializer.png),
            
            .scaleFactor(UIScreen.main.scale),
            .transition(transition),
            .diskCacheExpiration(.date(thumbnailExpirationDate))
//            ,.forceRefresh
        ]
        
        thumbnailView.kf.indicatorType = .activity
        thumbnailView.kf.setImage(with: imageUrl, placeholder: placeholder, options: options) { result in
//            switch result {
//            case .success(let value):
//                print("Task done for: \(value.source.url?.absoluteString ?? "")")
//            case .failure(let error):
//                print("Job failed: \(error.localizedDescription)")
//            }
        }
    }
    
    private func setPlaceholder(for post: Post) {
        thumbnailView.kf.cancelDownloadTask()
        thumbnailView.image = PostCell.getPlaceholder(for: post.type)
    }
    
    private func setBackground(for post: Post) {
        let overdue = post.date < Date()
        let bg: UIColor = overdue ? .secondarySystemBackground : .systemBackground
        contentView.backgroundColor = bg
    }
    
    private static func getThumbnailUrl(from post: Post) -> URL? {
        guard post.type == .link, let postUrl = post.url else { return nil }
        
        let url: String?
        if let thumbnailUrl = PostCell.getThumbnailUrl(from: postUrl) {
            url = thumbnailUrl
        } else if Helper.isImageUrl(postUrl) {
            url = postUrl
        } else {
            url = nil
        }
        
        if let url = url, let imageUrl = URL(string: url) {
            return imageUrl
        }
        
        return nil
    }
    
    private static func getThumbnailUrl(from url: String) -> String? {
        if let imgurUrl = Imgur.getThumbnailUrl(from: url) {
            return imgurUrl
        } else if let wallhavenUrl = Wallhaven.getThumbnailUrl(wallhavenUrl: url) {
            return wallhavenUrl
        } else {
            return nil
        }
    }
    
    private static func getPlaceholder(for type: Post.PostType) -> UIImage {
        // todo: different placeholders for link & text type posts
        return UIImage(named: PostCell.THUMBNAIL_TEXT_POST_PLACEHOLDER)!
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
