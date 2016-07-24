//
//  PartyTableCell.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-02-09.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//

import UIKit
import MarqueeLabel

class PartyTableCell: UITableViewCell {
	@IBOutlet weak var vitalityDot: UIImageView!
	@IBOutlet weak var venueLabel: UILabel!
	@IBOutlet weak var taglineLabel: MarqueeLabel!
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
					self.videoDate = greaterDate(one: venue.treats?.first?.time, two: videoDate)
					nc.addObserver(self, selector: #selector(PartyTableCell.updateVitality(_:)), name: Venue.VitalityUpdateNotification, object: venue)
					nc.addObserver(self, selector: #selector(PartyTableCell.updateTagline), name: Venue.PromotionUpdateNotification, object: venue)
				}
			}
			updateVitalityInfo()
			updateTagline()
		}
	}

	var videoTotal: Int = 0
	var videoDate: NSDate?

	private static let relativeFormatter: NSDateComponentsFormatter = {
		let formatter = NSDateComponentsFormatter()
		formatter.allowedUnits = [.Day, .Hour, .Minute]
		formatter.maximumUnitCount = 1
		formatter.unitsStyle = .Abbreviated
		formatter.zeroFormattingBehavior = .DropAll

		return formatter
	}()

	func updateTagline() {

	}

	func updateVitality(note: NSNotification) {
		if let venue = note.object as? Venue, delta = note.userInfo?["delta"] as? Int {
			videoTotal += delta
			if venue.vitality >= delta {
				videoDate = greaterDate(one: venue.treats?.first?.time, two: videoDate)
			} else {
				videoDate = venues?.reduce(nil) { greaterDate(one: $0, two: $1.treats?.first?.time) }
			}
			updateVitalityInfo()
		}
	}

	func updateVitalityInfo() {
		var vitality = ""
		switch videoTotal {
		case 0:
			vitality = "LowVitality"
		case 1...5:
			vitality = "MediumVitality"
		default:
			vitality = "HighVitality"
		}

		vitalityDot.image = UIImage(named: vitality)
		updateVitalityTime()
		updateTagline()
	}

	func updateVitalityTime() {
		if let time = videoDate {
            vitalityLabel.text = PartyTableCell.relativeFormatter.stringFromDate(time, toDate: NSDate(), classicThreshold: 2*24*60*60, substituteZero: NSLocalizedString("now", comment: "Zero interval short form")) ?? "?"
		} else {
			vitalityLabel.text = ""
		}
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
