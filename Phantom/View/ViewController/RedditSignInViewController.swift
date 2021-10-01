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
        loadUrlNoCookies(url)
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
                    self.performSignedInSegue()
                }
            }
            
        case .decline:
            dismiss()
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
    
    private func loadUrlNoCookies(_ url: URL) {
        Helper.deleteCookies(containing: "reddit") {
            self.webView.load(URLRequest(url: url))
        }
    }
    
    private func performSignedInSegue() {
        performSegue(withIdentifier: RedditSignInViewController.Segue.unwindRedditSignedIn.rawValue, sender: nil)
    }
    
    private func dismiss() {
        dismiss(animated: true, completion: nil)
    }
}
