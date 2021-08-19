//
//  AboutPresenter.swift
//  Phantom
//
//  Created by River on 2021/08/19.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

class AboutPresenter {
    // MARK: - Properties
    
    private weak var viewDelegate: AboutViewDelegate?
    
    private var items: [AboutItemType] = []
    
    // MARK: - View delegate
    
    func attachView(_ viewDelegate: AboutViewDelegate) {
        self.viewDelegate = viewDelegate
    }
    
    func detachView() {
        viewDelegate = nil
    }
    
    // MARK: - Public methods
    
    func viewDidLoad() {
        setupItems()
    }
    
    private func setupItems() {
        items = getAboutItems()
    }
    
    // MARK: - About data source
    
    func getItem(at index: Int) -> AboutItemType {
        return items[index]
    }
    
    func getItemCount() -> Int {
        return items.count
    }
    
    func didSelectItem(at index: Int) {
        let item = items[index]
        switch item {
        case .linkItem(let linkItem):
            linkItem.handler?()
        case .textItem(let textItem):
            textItem.handler?()
        default:
            fatalError("Unknown item")
        }
    }
    
    // MARK: - About items
    
    private func getAboutItems() -> [AboutItemType] {
        var items: [AboutItemType] = []
        
        items.append(getVersionItem())
        
        return items
    }
    
    // MARK: - General section
    
    private func getVersionItem() -> AboutItemType {
        let title = "Version"
        let text = "v1" // proper version
        
        let item = TextAboutItem(title: title, text: text, handler: nil)
        
        let itemType = AboutItemType.textItem(item: item)
        return itemType
    }
}
