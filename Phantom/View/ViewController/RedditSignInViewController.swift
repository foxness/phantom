//
//  RedditSignInViewController.swift
//  Phantom
//
//  Created by Rivershy on 2020/08/29.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import UIKit
import WebKit

// todo: loading icon while page is loading

class RedditSignInViewController: UIViewController, WKNavigationDelegate {
    enum Segue: String {
        case unwindRedditSignedIn = "unwindRedditSignedIn"
    }
    
    @IBOutlet weak var webView: WKWebView!
    
    var reddit = Reddit()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.customUserAgent = AppVariables.userAgent
        webView.navigationDelegate = self

        let url = reddit.getAuthUrl()
        
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
                    self.performSegue(withIdentifier: RedditSignInViewController.Segue.unwindRedditSignedIn.rawValue, sender: nil)
                }
            }
        }
        
        decisionHandler(.allow)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch Segue(rawValue: segue.identifier ?? "") {
        case .unwindRedditSignedIn:
            let dest = segue.destination as! RedditSignInReceiver
            dest.redditSignedIn(with: reddit)
        default:
            fatalError()
        }
    }
}
