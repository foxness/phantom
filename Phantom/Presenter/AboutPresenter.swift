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
    
    private static let TEXT_AUTHOR_NAME = "River Deem" // todo: get rid of "TEXT_"-like prefixes in all static variables? [ez]
    private static let TEXT_AUTHOR_EMAIL = "nymphadriel@gmail.com"
    private static let URL_PRIVACY_POLICY = "https://foxness.github.io/phantom-privacy-policy/"
    
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
    
    private func contactAuthorPressed() {
        let email = AboutPresenter.TEXT_AUTHOR_EMAIL
        let subject = "Phantom app"
        let body = "Phantom version: \(AppVariables.version)"
        
        viewDelegate?.showEmailComposer(to: email, subject: subject, body: body)
    }
    
    private func privacyPolicyPressed() {
        let privacyPolicyUrl = URL(string: AboutPresenter.URL_PRIVACY_POLICY)!
        
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
            getAuthorItem(),
            getContactItem(),
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
    
    private func getAuthorItem() -> AboutItemType {
        let title = "Designed & developed by"
        let text = AboutPresenter.TEXT_AUTHOR_NAME
        
        let item = TextAboutItem(title: title, text: text, handler: nil)
        let itemType = AboutItemType.textItem(item: item)
        
        return itemType
    }
    
    private func getContactItem() -> AboutItemType {
        let title = "Contact"
        let text = AboutPresenter.TEXT_AUTHOR_EMAIL
        
        let handler = { [self] in
            contactAuthorPressed()
        }
        
        let item = TextAboutItem(title: title, text: text, handler: handler)
        let itemType = AboutItemType.textItem(item: item)
        
        return itemType
    }
    
    private func getPrivacyPolicyItem() -> AboutItemType {
        let title = "Privacy Policy"
        
        let handler = { [self] in
            privacyPolicyPressed()
        }
        
        let item = LinkAboutItem(title: title, handler: handler)
        let itemType = AboutItemType.linkItem(item: item)
        
        return itemType
    }
}
