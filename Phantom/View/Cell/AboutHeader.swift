//
//  AboutHeader.swift
//  Phantom
//
//  Created by River on 2021/08/23.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import UIKit

class AboutHeader: UITableViewHeaderFooterView {
    static let IDENTIFIER = "AboutHeader"
    
    // todo: implement this cell init style in other cells?
    
//    let title = UILabel()
//    let image = UIImageView()
//
//    override init(reuseIdentifier: String?) {
//        super.init(reuseIdentifier: reuseIdentifier)
//
//        configureContents()
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
    
    // should only be called once. todo: add only once check?
    func addAboutHeaderView(_ ahv: UIView) {
        ahv.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(ahv)
        
        NSLayoutConstraint.activate([
            ahv.topAnchor.constraint(equalTo: contentView.topAnchor),
            ahv.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            ahv.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            ahv.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
//    private func configureContents() {
//        image.translatesAutoresizingMaskIntoConstraints = false
//        title.translatesAutoresizingMaskIntoConstraints = false
//
//        contentView.addSubview(image)
//        contentView.addSubview(title)
//
//        // Center the image vertically and place it near the leading
//        // edge of the view. Constrain its width and height to 50 points.
//        NSLayoutConstraint.activate([
//            image.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
//            image.widthAnchor.constraint(equalToConstant: 50),
//            image.heightAnchor.constraint(equalToConstant: 50),
//            image.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
//
//            // Center the label vertically, and use it to fill the remaining
//            // space in the header view.
//            title.heightAnchor.constraint(equalToConstant: 30),
//            title.leadingAnchor.constraint(equalTo: image.trailingAnchor,
//                                           constant: 8),
//            title.trailingAnchor.constraint(equalTo:
//                                                contentView.layoutMarginsGuide.trailingAnchor),
//            title.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
//        ])
//    }
}
