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
		if segue.identifier == "Third Party Segue" {
			if let targetVC = segue.destinationViewController as? RichTextController {
				targetVC.url = NSBundle.mainBundle().URLForResource("Acknowledgments", withExtension: "rtf")
			}
		}
	}

	@IBAction func recruit(sender: UIButton) {
		presentShareActions(self)
	}

	@IBAction func sequeFromThirdParty(segue: UIStoryboardSegue) {

	}
}
