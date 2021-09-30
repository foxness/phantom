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
        case unwindImgurSignedIn = "unwindImgurSignedIn"
    }
    
    @IBOutlet weak var webView: WKWebView!
    
    var imgur: Imgur = {
        let imgurClientId = AppVariables.Api.imgurClientId
        let imgurClientSecret = AppVariables.Api.imgurClientSecret
        let imgurRedirectUri = AppVariables.Api.imgurRedirectUri
        
        return Imgur(clientId: imgurClientId,
                     clientSecret: imgurClientSecret,
                     redirectUri: imgurRedirectUri)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.customUserAgent = AppVariables.userAgent
        webView.navigationDelegate = self

        let url = imgur.getAuthUrl()
        
        // use just loadUrl(url) instead of you wanna remember sign in (you don't wanna remember sign in tbh)
        Helper.deleteCookies(containing: "imgur") {
            self.loadUrl(url)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url!
        let response = imgur.getUserResponse(to: url)
        if response == .allow && imgur.isSignedIn {
            performSegue(withIdentifier: ImgurSignInViewController.Segue.unwindImgurSignedIn.rawValue, sender: nil)
        }
        
        decisionHandler(.allow)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let dest = segue.destination as! ImgurSignInReceiver
        dest.imgurSignedIn(with: imgur)
    }
    
    private func loadUrl(_ url: URL) {
        webView.load(URLRequest(url: url))
    }
}
