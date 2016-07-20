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

	@IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var postButton: UIButton!
	
	override func viewDidLoad() {
        UIView.animateWithDuration(1.0, delay: 0, options: [.Autoreverse, .Repeat, .AllowUserInteraction], animations: { self.shareButton.alpha = 0.5; self.postButton.alpha = 0.5 }, completion: nil)
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		navigationController?.navigationBar.topItem?.title = NSLocalizedString("Share", comment: "Recruitment page navigation title")
	}

	@IBAction func recruit(sender: UIButton) {
		presentShareActionsOn(self, atOrigin: sender, withPrompt: NSLocalizedString("Share PartyUP", comment: "Share action prompt"))
	}

    @IBAction func post(sender: UIButton) {
        navigationController?.popToRootViewControllerAnimated(true)
        NSNotificationCenter.defaultCenter().postNotificationName(PartyUpConstants.RecordVideoNotification, object: nil)
    }
    
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if let avc = segue.destinationViewController as? AdvertisingOverlayController {
			avc.url = ad
		}
	}
}
