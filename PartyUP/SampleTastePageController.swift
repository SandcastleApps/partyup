//
//  SampleTastePageController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-24.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit
import AVFoundation

class SampleTastePageController: UIViewController {

	private static let timeFormatter: NSDateFormatter = { let formatter = NSDateFormatter(); formatter.timeStyle = .MediumStyle; formatter.dateStyle = .NoStyle; return formatter }()

	var page: Int!
	var sample: Sample!

	@IBOutlet weak var commentLabel: UILabel!
	@IBOutlet weak var timeLabel: UILabel!
	@IBOutlet weak var commentBackdrop: UIVisualEffectView!

    override func viewDidLoad() {
        super.viewDidLoad()

		timeLabel.text = SampleTastePageController.timeFormatter.stringFromDate(sample.time)
		if let comment = sample.comment {
			commentLabel.text = comment
			commentLabel.hidden = false
			commentBackdrop.hidden = false
		}
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if let videoVC = segue.destinationViewController as? VideoViewController {
			videoVC.loop = true
			videoVC.rate = 1.0
			videoVC.player = AVPlayer(URL: PartyUpConstants.ContentDistribution.URLByAppendingPathComponent(sample.media.path!))
		}
    }


}
