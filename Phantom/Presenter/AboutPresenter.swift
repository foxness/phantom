//
//  AboutPresenter.swift
//  Phantom
//
//  Created by River on 2021/08/19.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

// todo:
// - version DONE
// - contact author
// - rate on app store
// - privacy policy

// todo: easter egg on pressing app version N times?

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
        }
    }
    
    // MARK: - About items
    
    private func getAboutItems() -> [AboutItemType] {
        var items: [AboutItemType] = []
        
        items.append(getVersionItem())
        
        return items
    }
    
    private func getVersionItem() -> AboutItemType {
        let title = "Version"
        let text = Bundle.main.prettyAppVersion
        
        let item = TextAboutItem(title: title, text: text, handler: nil)
        
        let itemType = AboutItemType.textItem(item: item)
        return itemType
    }
}
