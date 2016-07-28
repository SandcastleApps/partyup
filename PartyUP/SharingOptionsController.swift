//
//  SharingOptionsController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-07-25.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//

import UIKit

class SharingOptionsController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

		if !AuthenticationManager.shared.isLoggedIn {
			loginButton.setTitle(NSLocalizedString("Login to see more content", comment: "Recruitment page authenticate button"), forState: .Normal)
			loginButton.enabled = true
		} else {
			let authenticated = NSLocalizedString("Hey", comment: "Recruitment page authenticated button") + " " + (AuthenticationManager.shared.user.aliases.first ?? "Anonymous")
			loginButton.setTitle(authenticated, forState: .Disabled)
		}
    }

	@IBOutlet weak var loginButton: UIButton!

	@IBAction func recruit(sender: UIButton) {
		presentShareActionsOn(self, atOrigin: sender, withPrompt: NSLocalizedString("Share PartyUP", comment: "Share action prompt"))
	}

	@IBAction func post(sender: UIButton) {
		navigationController?.popToRootViewControllerAnimated(true)
		NSNotificationCenter.defaultCenter().postNotificationName(PartyUpConstants.RecordVideoNotification, object: nil)
	}

	@IBAction func login(sender: UIButton) {
		if !AuthenticationManager.shared.isLoggedIn {
			AuthenticationFlow.shared.startOnController(self).addAction { manager, cancelled in
				if manager.isLoggedIn {
					self.navigationController?.popToRootViewControllerAnimated(true)
				}
			}
		}
	}

}
