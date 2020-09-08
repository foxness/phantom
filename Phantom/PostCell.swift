//
//  PostCell.swift
//  Phantom
//
//  Created by user179800 on 9/4/20.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import UIKit

class PostCell: UITableViewCell {
    static let IDENTIFIER = "PostCell"
    
    @IBOutlet weak var ptitle: UILabel!
    @IBOutlet weak var ptext: UILabel!
    @IBOutlet weak var pimage: UIImageView!
    @IBOutlet weak var pdate: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func set(post: Post) {
        ptitle.text = post.title
        ptext.text = post.text
        pdate.text = PostCell.dateToString(post.date)
    }
    
    static func dateToString(_ date: Date) -> String { // in X hours
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
