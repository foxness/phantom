//
//  LoginViewController.swift
//  Phantom
//
//  Created by user179800 on 8/29/20.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import UIKit
import WebKit

class LoginViewController: UIViewController, WKNavigationDelegate {
    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.navigationDelegate = self

        let url = getAuthUrl()
        webView.load(URLRequest(url: url))
    }
            
    func getAuthUrl() -> URL {
        // https://www.reddit.com/api/v1/authorize?client_id=CLIENT_ID&response_type=TYPE&state=RANDOM_STRING&redirect_uri=URI&duration=DURATION&scope=SCOPE_STRING
        
        let clientId = "XTWjw2332iSmmQ"
        let isCompact = false
        let responseType = "code"
        let state = "asd"
        let redirectUri = "https://localhost/phantomdev"
        let duration = "permanent"
        let scope = "identity submit"
            
        var urlc = URLComponents(string: "https://www.reddit.com/api/v1/authorize\(isCompact ? ".compact" : "")")!
        
        let params = ["client_id": clientId,
                      "response_type": responseType,
                      "state": state,
                      "redirect_uri": redirectUri,
                      "duration": duration,
                      "scope": scope]
        
        urlc.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        return urlc.url!
    }
}
