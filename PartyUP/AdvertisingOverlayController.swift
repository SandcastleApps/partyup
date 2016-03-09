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
				web?.loadRequest(NSURLRequest(URL: url))
			}
		}
	}

	var web: WKWebView! {
		didSet {
			if let url = url {
				web?.loadRequest(NSURLRequest(URL: url))
			}
		}
	}
    
    override func loadView() {
        super.loadView()
        web = WKWebView(frame: view.bounds)
        web.opaque = false
        web.scrollView.scrollEnabled = false
        view = web
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

}
