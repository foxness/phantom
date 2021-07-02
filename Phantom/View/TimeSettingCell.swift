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
        handler = nil
    }
    
    public func configure(with option: TimeSettingsOption) {
        titleLabel.text = option.title
        datePicker.date = Helper.timeOfDayToDate(option.timeOfDay)
        handler = option.handler
    }
    
    @IBAction func dateEditingDidEnd(datePicker: UIDatePicker) {
        guard let handler = handler else { return }
        
        let timeOfDay = Helper.dateToTimeOfDay(datePicker.date)
        handler(timeOfDay)
    }
}
