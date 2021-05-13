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
    
    private static let TEXT_POST_PLACEHOLDER = "thumbnail_text_post"
    
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
        
//        let f = UIScreen.main.scale
//        let w = pimage.bounds.width * f
//        let h = pimage.bounds.height * f
//
//        Log.p("viewW: \(w), viewH: \(h)")
//
//        let ss = pimage.image!.scale
//        let ww = pimage.image!.size.width * ss
//        let hh = pimage.image!.size.height * ss
//
//        Log.p("imgW: \(ww), imgH: \(hh)")
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
        let processor = CroppingImageProcessor(size: thumbnailView.bounds.size)
            |> DownsamplingImageProcessor(size: thumbnailView.bounds.size)
            |> RoundCornerImageProcessor(cornerRadius: 5)
        
        let placeholder = PostCell.getPlaceholder(for: post.type)
        let options: KingfisherOptionsInfo = [
            .processor(processor),
            .cacheSerializer(FormatIndicatedCacheSerializer.jpeg),
            .scaleFactor(UIScreen.main.scale),
            .transition(.flipFromRight(0.5)),
//            .forceRefresh
        ]
        
        thumbnailView.kf.indicatorType = .activity
        thumbnailView.kf.setImage(with: imageUrl, placeholder: placeholder, options: options) {
            result in
            switch result {
            case .success(let value):
                print("Task done for: \(value.source.url?.absoluteString ?? "") ... \(value.image.size)")
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
        return UIImage(named: PostCell.TEXT_POST_PLACEHOLDER)!
    }
    
    private static func dateToString(_ date: Date) -> String { // "in X hours"
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
