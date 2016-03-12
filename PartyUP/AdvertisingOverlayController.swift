//
//  AdvertisingOverlayController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-03-09.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//

import UIKit
import WebKit

class AdvertisingOverlayController: UIViewController, PageProtocol {
    
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
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

		if let url = url {
			webView.loadRequest(NSURLRequest(URL: url))
		}
    }

}
