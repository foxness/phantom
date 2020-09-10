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
        
        pimage.image = UIImage(named: "thumbnail_text_post")!
        
        let overdue = post.date < Date()
        let bg: UIColor = overdue ? .secondarySystemBackground : .systemBackground
        contentView.backgroundColor = bg
        
        /*let f = UIScreen.main.scale
        let w = pimage.bounds.width * f
        let h = pimage.bounds.height * f
        
        Log.p("viewW: \(w), viewH: \(h)")
        
        let ss = pimage.image!.scale
        let ww = pimage.image!.size.width * ss
        let hh = pimage.image!.size.height * ss
        
        Log.p("imgW: \(ww), imgH: \(hh)")*/
    }
    
    static func dateToString(_ date: Date) -> String { // in X hours
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
