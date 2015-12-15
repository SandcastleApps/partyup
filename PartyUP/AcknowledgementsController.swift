//
//  AcknowledgementsController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-12-03.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit

class AcknowledgementsController: UITableViewController {

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

	}

	@IBAction func tutorial(sender: UIButton) {
		let story = UIStoryboard.init(name: "Tutorial", bundle: nil)
		if let tutorial = story.instantiateInitialViewController() {
			presentViewController(tutorial, animated: true, completion: nil)
		}
	}

	@IBAction func recruit(sender: UIButton) {
		presentShareActions(self)
	}

	@IBAction func pushThirdParty(sender: UITapGestureRecognizer) {
		if let richVC = storyboard?.instantiateViewControllerWithIdentifier("Rich Text Controller") as? RichTextController {
			richVC.url = NSBundle.mainBundle().URLForResource("Acknowledgments", withExtension: "rtf")
			navigationController?.pushViewController(richVC, animated: true)
		}
	}

	@IBAction func pushFeedback(sender: UIButton) {
		if let webVC = storyboard?.instantiateViewControllerWithIdentifier("Feedback Controller") as? WebPageController {
			webVC.url = NSURL(string: "https://www.surveymonkey.com/r/***REMOVED***")
			webVC.purpose = NSLocalizedString("Feedback", comment: "Title of the Feedback webview")
			navigationController?.pushViewController(webVC, animated: true)
		}
	}
	
	@IBAction func pushSupport(sender: UIButton) {
		if let webVC = storyboard?.instantiateViewControllerWithIdentifier("Feedback Controller") as? WebPageController {
			webVC.url = NSURL(string: "http://www.partyuptonight.com/support.html")
			webVC.purpose = NSLocalizedString("Support", comment: "Title of the Support webview")
			navigationController?.pushViewController(webVC, animated: true)
		}
	}

	@IBAction func segueFromThirdParty(segue: UIStoryboardSegue) {

	}

	@IBAction func segueFromTutorial(segue: UIStoryboardSegue) {

	}
}
