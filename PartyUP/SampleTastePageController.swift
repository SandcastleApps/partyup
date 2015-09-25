//
//  SampleTastePageController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-24.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit

class SampleTastePageController: UIViewController {

	private static let timeFormatter: NSDateFormatter = { let formatter = NSDateFormatter(); formatter.timeStyle = .MediumStyle; formatter.dateStyle = .NoStyle; return formatter }()

	var page: Int!
	var sample: Sample!

	@IBOutlet weak var commentLabel: UILabel!
	@IBOutlet weak var timeLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

		timeLabel.text = SampleTastePageController.timeFormatter.stringFromDate(sample.time)
		if let comment = sample.comment {
			commentLabel.text = comment
			commentLabel.hidden = false
		}
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if let videoVC = segue.destinationViewController as? VideoViewController {
			videoVC.url = PartyUpConstants.ContentDistribution.URLByAppendingPathComponent(sample.media.path!)
		}
    }


}