//
//  ImgurSignInViewController.swift
//  Phantom
//
//  Created by River on 2021/04/28.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import UIKit
import WebKit

class ImgurSignInViewController: UIViewController, WKNavigationDelegate {
    enum Segue: String {
        case imgurBackToList = "backImgurToList"
    }
    
    @IBOutlet weak var webView: WKWebView!
    
    var imgur = Imgur()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.customUserAgent = Requests.getUserAgent()
        webView.navigationDelegate = self

        let url = imgur.getAuthUrl()
        
        let rememberSignIn = true // todo: remove this or add to debugvariable
        if rememberSignIn {
            webView.load(URLRequest(url: url))
        } else {
            deleteCookies {
                self.webView.load(URLRequest(url: url))
            }
        }
    }
    
    func deleteCookies(completion: @escaping () -> Void) {
        let dataStore = WKWebsiteDataStore.default()
        dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: records.filter { $0.displayName.contains("imgur") }, completionHandler: completion )}
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url!
        let response = imgur.getUserResponse(to: url)
        if response == .allow && imgur.isLoggedIn {
            performSegue(withIdentifier: ImgurSignInViewController.Segue.imgurBackToList.rawValue, sender: nil)
        }
        
        decisionHandler(.allow)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let dest = segue.destination as! PostTableViewController
        dest.imgurSignedIn(with: imgur)
    }
}
