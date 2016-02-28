//
//  ShareUtilities.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-12-12.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit
import Social
import Flurry_iOS_SDK

func presentShareSheetOn(presenting: UIViewController,
	viaService service: String,
	withMessage message: String,
	url: NSURL?,
	image: UIImage?) {
	if SLComposeViewController.isAvailableForServiceType(service) {
		let shareSheet:SLComposeViewController = SLComposeViewController(forServiceType: service)
		shareSheet.setInitialText(message)
		shareSheet.addURL(url)
		shareSheet.addImage(image)
		presenting.presentViewController(shareSheet, animated: true, completion:  nil)
	} else {
		let alert = UIAlertController(
			title: NSLocalizedString("Accounts", comment: "Share login alert title"),
			message: NSLocalizedString("Please login to a \(service.componentsSeparatedByString(".").last!) account to share.", comment: "Share login alert message"), preferredStyle: UIAlertControllerStyle.Alert)
		alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Share login alert action"), style: .Default, handler: nil))
		presenting.presentViewController(alert, animated: true, completion: nil)
	}
}


func presentShareActionsOn(presenting: UIViewController,
		atOrigin origin: UIView,
        withPrompt prompt: String,
	withMessage message: String = NSLocalizedString("Lets Party!\n", comment: "Recruitment default text"),
					url: NSURL? = NSURL(string: "http://partyuptonight.com"),
				  image: UIImage? = UIImage(named: "BlackLogo")) {
	let sheet = UIAlertController(title: prompt, message: nil, preferredStyle: .ActionSheet)
	let services = ["Facebook" : SLServiceTypeFacebook, "Twitter" : SLServiceTypeTwitter]

	for (title, service) in services {
		sheet.addAction(UIAlertAction(title: title, style: .Default) { _ in
			presentShareSheetOn(presenting, viaService: service, withMessage: message, url: url, image: image)
			Flurry.logEvent(prompt, withParameters: ["service" : title])
		})
	}
	sheet.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Share sheet cancel action"), style: .Cancel, handler: nil))
    
    if let pop = sheet.popoverPresentationController {
        pop.sourceView = origin
        pop.sourceRect = origin.bounds
    }
    
	presenting.presentViewController(sheet, animated: true, completion: nil)
}
