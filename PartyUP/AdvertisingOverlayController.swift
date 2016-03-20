//
//  AdvertisingOverlayController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-03-09.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//

import UIKit
import WebKit
import Flurry_iOS_SDK

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
        if let url = url {
            Flurry.logEvent("Advertisement_Viewed", withParameters: ["url" : url.description, "overlay" : page == nil])
        }

		if page != nil {
			navigationController?.navigationBar.topItem?.title = NSLocalizedString("Advertisement", comment: "Avdertisement page navigation title")
		}
	}
    
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.URL where navigationAction.navigationType == .LinkActivated {
            UIApplication.sharedApplication().openURL(url)
            Flurry.logEvent("Advertisement_Navigated", withParameters: ["target" : url.description])
            decisionHandler(.Cancel)
        } else {
            decisionHandler(.Allow)
        }
    }
}
