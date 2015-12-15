//
//  WebPageController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-12-14.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit

class WebPageController: UIViewController {

	@IBOutlet weak var webView: UIWebView! {
		didSet {
			if let url = url {
				webView?.loadRequest(NSURLRequest(URL: url))
			}
		}
	}

	var url: NSURL? {
		didSet {
			if let url = url {
				webView?.loadRequest(NSURLRequest(URL: url))
			}
		}
	}

}
