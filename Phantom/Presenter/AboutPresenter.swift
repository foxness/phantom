//
//  AboutPresenter.swift
//  Phantom
//
//  Created by River on 2021/08/19.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import Foundation

// todo: rate on app store item

// todo: easter egg on pressing app version N times?
// todo: extract all app name ("Phantom") strings

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
    
    // MARK: - Private methods
    
    private func setupItems() {
        items = getAboutItems()
    }
    
    private func developerItemPressed() {
        let developerTwitterUrl = URL(string: AppVariables.Developer.twitterUrl)!
        
        viewDelegate?.open(url: developerTwitterUrl)
    }
    
    private func contactItemPressed() {
        let email = AppVariables.Developer.contactEmail
        let subject = "Phantom app"
        let body = "Phantom version: \(AppVariables.version)"
        
        viewDelegate?.showEmailComposer(to: email, subject: subject, body: body)
    }
    
    private func appStoreItemPressed() {
        let appStoreUrl = URL(string: AppVariables.appStoreUrl)!
        
        viewDelegate?.open(url: appStoreUrl)
    }
    
    private func privacyPolicyItemPressed() {
        let privacyPolicyUrl = URL(string: AppVariables.privacyPolicyUrl)!
        
        viewDelegate?.open(url: privacyPolicyUrl)
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
        [
            getVersionItem(),
            getDeveloperItem(),
            getContactItem(),
            getAppStoreItem(),
            getPrivacyPolicyItem()
        ]
    }
    
    private func getVersionItem() -> AboutItemType {
        let title = "Version"
        let text = AppVariables.version
        
        let item = TextAboutItem(title: title, text: text, handler: nil)
        let itemType = AboutItemType.textItem(item: item)
        
        return itemType
    }
    
    private func getDeveloperItem() -> AboutItemType {
        let title = "Designed & developed by"
        let text = AppVariables.Developer.name
        
        let handler = { [self] in
            developerItemPressed()
        }
        
        let item = TextAboutItem(title: title, text: text, handler: handler)
        let itemType = AboutItemType.textItem(item: item)
        
        return itemType
    }
    
    private func getContactItem() -> AboutItemType {
        let title = "Contact"
        let text = AppVariables.Developer.contactEmail
        
        let handler = { [self] in
            contactItemPressed()
        }
        
        let item = TextAboutItem(title: title, text: text, handler: handler)
        let itemType = AboutItemType.textItem(item: item)
        
        return itemType
    }
    
    private func getAppStoreItem() -> AboutItemType {
        let title = "Rate on the App Store"
        
        let handler = { [self] in
            appStoreItemPressed()
        }
        
        let item = LinkAboutItem(title: title, handler: handler)
        let itemType = AboutItemType.linkItem(item: item)
        
        return itemType
    }
    
    private func getPrivacyPolicyItem() -> AboutItemType {
        let title = "Privacy Policy"
        
        let handler = { [self] in
            privacyPolicyItemPressed()
        }
        
        let item = LinkAboutItem(title: title, handler: handler)
        let itemType = AboutItemType.linkItem(item: item)
        
        return itemType
    }
}
