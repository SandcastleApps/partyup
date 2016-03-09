//
//  AdvertisingOverlayController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-03-09.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//

import UIKit

class AdvertisingOverlayController: UIViewController {

	var url: NSURL? {
		didSet {
			if let url = url {
				web?.loadRequest(NSURLRequest(URL: url))
			}
		}
	}

	@IBOutlet weak var web: UIWebView! {
		didSet {
			if let url = url {
				web?.loadRequest(NSURLRequest(URL: url))
			}
		}
	}

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

}
