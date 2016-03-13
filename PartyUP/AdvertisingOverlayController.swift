//
//  AdvertisingOverlayController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-03-09.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//

import UIKit
import WebKit

class AdvertisingOverlayController: UIViewController, WKNavigationDelegate, PageProtocol {
    
    var page: Int!

	var url: NSURL? {
		didSet {
			if let url = url {
				webView?.loadRequest(NSURLRequest(URL: url))
			}
		}
	}

	private var webView: WKWebView!
    
    override func loadView() {
        super.loadView()
        webView = WKWebView()
        webView.opaque = false
        webView.scrollView.scrollEnabled = false
        webView.allowsBackForwardNavigationGestures = false
        webView.navigationDelegate = self
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

		if let url = url {
			webView.loadRequest(NSURLRequest(URL: url))
		}
    }

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		if page != nil {
			navigationController?.navigationBar.topItem?.title = NSLocalizedString("Advertisement", comment: "Avdertisement page navigation title")
		}
	}
    
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.URL where navigationAction.navigationType == .LinkActivated {
            UIApplication.sharedApplication().openURL(url)
            decisionHandler(.Cancel)
        } else {
            decisionHandler(.Allow)
        }
    }
}
