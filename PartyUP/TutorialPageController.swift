//
//  TutorialPageController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-12-13.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit

class TutorialPageController: UIViewController {

	var page: Int!
	var pageCount: Int!

	@IBOutlet weak var doneButton: UIButton!
	@IBOutlet weak var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

		imageView.image = UIImage(named: "Tutorial_\(page)")
    }

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		doneButton.hidden = page < pageCount - 1

		if !doneButton.hidden {
			UIView.animateWithDuration(1, delay: 0, options: [.Repeat, .Autoreverse, .AllowUserInteraction], animations: { self.doneButton.alpha = 0.25 }, completion: nil)
		}
	}
}
