//
//  LoginViewController.swift
//  Phantom
//
//  Created by Rivershy on 2020/08/29.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import UIKit
import WebKit

class LoginViewController: UIViewController, WKNavigationDelegate {
    enum Segue: String {
        case backLoginToList
    }
    
    @IBOutlet weak var webView: WKWebView!
    
    var reddit = Reddit()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.customUserAgent = Requests.getUserAgent()
        webView.navigationDelegate = self

        let url = reddit.getAuthUrl()
        
        let rememberLogin = true
        if rememberLogin {
            webView.load(URLRequest(url: url))
        } else {
            deleteCookies {
                self.webView.load(URLRequest(url: url))
            }
        }
    }
    
    func deleteCookies(completion: @escaping () -> Void) {
        let dataStore = WKWebsiteDataStore.default()
        dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: records.filter { $0.displayName.contains("reddit") }, completionHandler: completion )}
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url!
        let response = reddit.getUserResponse(to: url)
        if response == .allow {
            DispatchQueue.global(qos: .userInitiated).async {
                Log.p("fetching tokens")
                try! self.reddit.fetchAuthTokens()
                try! self.reddit.getIdentity()
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: LoginViewController.Segue.backLoginToList.rawValue, sender: nil)
                }
            }
        }
        
        decisionHandler(.allow)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let dest = segue.destination as! PostTableViewController
        dest.loginReddit(with: reddit)
    }
}
