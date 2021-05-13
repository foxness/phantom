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
        var shouldSetPlaceholder = true
        
        if post.type == .link, let url = post.url {
            var imageUrl: String? = nil
            if let wallhavenThumbnailUrl = Wallhaven.getThumbnailUrl(wallhavenUrl: url) {
                imageUrl = wallhavenThumbnailUrl
            } else if Helper.isImageUrl(url) {
                imageUrl = url
            }
            
            if let imageUrl = imageUrl, let goodImageUrl = URL(string: imageUrl) {
                thumbnailView.kf.setImage(with: goodImageUrl)
                shouldSetPlaceholder = false
            }
        }
        
        if shouldSetPlaceholder {
            thumbnailView.image = UIImage(named: "thumbnail_text_post")!
        }
    }
    
    private func setBackground(for post: Post) {
        let overdue = post.date < Date()
        let bg: UIColor = overdue ? .secondarySystemBackground : .systemBackground
        contentView.backgroundColor = bg
    }
    
    private static func dateToString(_ date: Date) -> String { // "in X hours"
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
