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
    
    var reddit: Reddit = {
        let redditClientId = AppVariables.Api.redditClientId
        let redditRedirectUri = AppVariables.Api.redditRedirectUri
        
        return Reddit(clientId: redditClientId, redirectUri: redditRedirectUri)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.customUserAgent = AppVariables.userAgent
        webView.navigationDelegate = self

        let url = reddit.getAuthUrl()
        
        // use just loadUrl(url) instead of you wanna remember sign in (you don't wanna remember sign in tbh)
        Helper.deleteCookies(containing: "reddit") {
            self.loadUrl(url)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url!
        let response = reddit.getUserResponse(to: url)
        
        switch response {
        case .none: break
            
        case .allow:
            DispatchQueue.global(qos: .userInitiated).async {
                Log.p("fetching tokens")
                try! self.reddit.fetchAuthTokens()
                try! self.reddit.getIdentity()
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: RedditSignInViewController.Segue.unwindRedditSignedIn.rawValue, sender: nil)
                }
            }
            
        case .decline:
            dismiss(animated: true, completion: nil)
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
    
    private func loadUrl(_ url: URL) {
        webView.load(URLRequest(url: url))
    }
}
