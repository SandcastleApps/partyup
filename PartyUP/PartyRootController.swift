//
//  PartyRootController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-11-07.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit

class PartyRootController: UIViewController {

	private var partyPicker: PartyPickerController!

    override func viewDidLoad() {
        super.viewDidLoad()
		navigationItem.titleView = PartyUpConstants.TitleLogo()
		//navigationItem.backBarButtonItem = UIBarButtonItem(image: UIImage(named: "Back"), style: .Plain, target: nil, action: nil)
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "Party Embed Segue" {
			partyPicker = segue.destinationViewController as! PartyPickerController
		}
		if segue.identifier == "Bake Sample Segue" {
			let bakerVC = segue.destinationViewController as! BakeRootController
			bakerVC.venues = partyPicker.venues
		}
	}

	@IBAction func sequeFromBaking(segue: UIStoryboardSegue) {

	}

	@IBAction func segueFromTasting(segue: UIStoryboardSegue) {

	}
}
