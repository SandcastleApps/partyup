//
//  RecruitPageController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-12-04.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit
import Flurry_iOS_SDK

class RecruitPageController: UIViewController, PageProtocol {

	var page: Int!
	var sample: Sample!

	@IBAction func recruit(sender: UIButton) {
		let text = NSLocalizedString("Lets Party!\n", comment: "Recruitment default text")
		let url = NSURL(string: "http://partyuptonight.com")
		let image = UIImage(named: "BlackLogo")

		let share = UIActivityViewController(activityItems: [text,image!,url!], applicationActivities: nil)
		share.excludedActivityTypes = [
			UIActivityTypePostToWeibo,
			UIActivityTypePrint,
			UIActivityTypeCopyToPasteboard,
			UIActivityTypeAssignToContact,
			UIActivityTypeSaveToCameraRoll,
			UIActivityTypeAddToReadingList,
			UIActivityTypePostToFlickr,
			UIActivityTypePostToVimeo,
			UIActivityTypePostToTencentWeibo,
			UIActivityTypeAirDrop
		]

		presentViewController(share, animated: true, completion: nil)

		Flurry.logEvent("Recruiting")
	}

}
