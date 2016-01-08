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

	@IBOutlet weak var shareButton: UIButton!
	
	override func viewDidLoad() {
		UIView.animateWithDuration(1.0, delay: 0, options: [.Autoreverse, .Repeat, .AllowUserInteraction], animations: { self.shareButton.alpha = 0.5 }, completion: nil)
	}

	@IBAction func recruit(sender: UIButton) {
		presentShareActions(self)
	}

}
