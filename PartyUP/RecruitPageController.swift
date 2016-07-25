//
//  RecruitPageController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-12-04.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit

class RecruitPageController: UIViewController, PageProtocol {

	var page: Int!

	var ad: NSURL?

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		navigationController?.navigationBar.topItem?.title = NSLocalizedString("Share", comment: "Recruitment page navigation title")
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if let avc = segue.destinationViewController as? AdvertisingOverlayController {
			avc.url = ad
		}
	}
}
