//
//  TimeSettingCell.swift
//  Phantom
//
//  Created by River on 2021/07/02.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import UIKit

class TimeSettingCell: UITableViewCell {
    static let IDENTIFIER = "TimeSettingCell"
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    private var handler: ((TimeInterval) -> Void)?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        titleLabel.text = nil
    }
    
    public func configure(with option: TimeSettingsOption) {
        titleLabel.text = option.title
        datePicker.date = Date().startOfDay + option.timeOfDay
    }
    
    @IBAction func dateEditingDidEnd(datePicker: UIDatePicker) {
        let timeOfDay = datePicker.date.startOfDay.distance(to: datePicker.date)
        handler?(timeOfDay)
    }
}
