//
//  PartyTableCell.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-02-09.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//

import UIKit

class PartyTableCell: UITableViewCell {
	@IBOutlet weak var vitalityDot: UILabel!
	@IBOutlet weak var venueLabel: UILabel!
	@IBOutlet weak var taglineLabel: UILabel!
	@IBOutlet weak var vitalityLabel: UILabel!

	var title = "" {
		didSet {
			venueLabel?.text = title
		}
	}

	var venues: [Venue]? {
		willSet {
			NSNotificationCenter.defaultCenter().removeObserver(self)
		}
		didSet {
			if let venues = venues {
				let nc = NSNotificationCenter.defaultCenter()
				videoTotal = 0
				videoDate = nil
				venues.forEach { venue in
					self.videoTotal += venue.vitality
					self.videoDate = greaterDate(one: venue.samples?.first?.time, two: videoDate)
					nc.addObserver(self, selector: Selector("updateVitality:"), name: Venue.VitalityUpdateNotification, object: venue)
					nc.addObserver(self, selector: Selector("updateTagline"), name: Venue.PromotionUpdateNotification, object: venue)
				}
			}
			updateVitalityInfo()
			updateTagline()
		}
	}

	var videoTotal: Int = 0
	var videoDate: NSDate?

	func updateTagline() {

	}

	func updateVitality(note: NSNotification) {
		if let venue = note.object as? Venue, oldCount = note.userInfo?["old count"] as? Int {
			videoTotal += venue.vitality - oldCount
			videoDate = greaterDate(one: venue.samples?.first?.time, two: videoDate)
			updateVitalityInfo()
		}
	}

	func updateVitalityInfo() {
		var vitality = ""
		switch videoTotal {
		case 0:
			vitality = "🎈"
		case 1...5:
			vitality = "💃🏻"
		default:
			vitality = "🔥"
		}

		vitalityDot.text = vitality
		updateVitalityTime()
		updateTagline()
	}

	func updateVitalityTime() {

	}
}

private func greaterDate(one one: NSDate?, two: NSDate?) -> NSDate? {
	if let one = one {
		if let two = two {
			return one.compare(two) == .OrderedDescending ? one : two
		} else {
			return one
		}
	} else {
		return two
	}
}
