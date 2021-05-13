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
    private static let THUMBNAIL_CORNER_RADIUS: CGFloat = 5
    private static let THUMBNAIL_TRANSITION_DURATION: TimeInterval = 0.5
    
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
        if let imageUrl = PostCell.getImageUrl(from: post) {
            setThumbnail(for: post, with: imageUrl)
        } else {
            setPlaceholder(for: post)
        }
    }
    
    private func setThumbnail(for post: Post, with imageUrl: URL) {
        let thumbnailSize = thumbnailView.bounds.size
        let processor = AspectCroppingImageProcessor(aspectRatio: thumbnailSize)
            |> DownsamplingImageProcessor(size: thumbnailSize)
            |> RoundCornerImageProcessor(cornerRadius: PostCell.THUMBNAIL_CORNER_RADIUS)
        
        let placeholder = PostCell.getPlaceholder(for: post.type)
        let options: KingfisherOptionsInfo = [
            .processor(processor),
            .cacheSerializer(FormatIndicatedCacheSerializer.jpeg),
            .scaleFactor(UIScreen.main.scale),
            .transition(.flipFromRight(PostCell.THUMBNAIL_TRANSITION_DURATION)),
            .forceRefresh
        ]
        
        thumbnailView.kf.indicatorType = .activity
        thumbnailView.kf.setImage(with: imageUrl, placeholder: placeholder, options: options) {
            result in
            switch result {
            case .success(let value):
                print("Task done for: \(value.source.url?.absoluteString ?? "")")
            case .failure(let error):
                print("Job failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func setPlaceholder(for post: Post) {
        thumbnailView.image = PostCell.getPlaceholder(for: post.type)
    }
    
    private func setBackground(for post: Post) {
        let overdue = post.date < Date()
        let bg: UIColor = overdue ? .secondarySystemBackground : .systemBackground
        contentView.backgroundColor = bg
    }
    
    private static func getImageUrl(from post: Post) -> URL? {
        guard post.type == .link, let postUrl = post.url else { return nil }
        
        var url: String? = nil
        if let wallhavenThumbnailUrl = Wallhaven.getThumbnailUrl(wallhavenUrl: postUrl) {
            url = wallhavenThumbnailUrl
        } else if Helper.isImageUrl(postUrl) {
            url = postUrl
        }
        
        if let url = url, let imageUrl = URL(string: url) {
            return imageUrl
        }
        
        return nil
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
