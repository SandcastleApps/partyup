//
//  VenueTableCell.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-12-29.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit

class VenueTableCell: UITableViewCell {

    @IBOutlet weak var vitalityDot: UILabel!
	@IBOutlet weak private var venueLabel: UILabel!
	@IBOutlet weak private var detailLabel: UILabel!
	@IBOutlet weak private var vitalityLabel: UILabel!

	var venue: Venue? {
		willSet {
			NSNotificationCenter.defaultCenter().removeObserver(self)
		}

		didSet {
			if let venue = venue {
				let nc = NSNotificationCenter.defaultCenter()
				nc.addObserver(self, selector: Selector("updateVitalityDisplay"), name: Venue.VitalityUpdateNotification, object: venue)
				nc.addObserver(self, selector: Selector("updatePromotionalMaterial"), name: Venue.PromotionUpdateNotification, object: venue)
				venueLabel.text = venue.name ?? NSLocalizedString("Mysterious Venue", comment: "Default in cell when venue name is nil")
				updateVitalityDisplay()
				updatePromotionalMaterial()
			}
		}
	}

	func updatePromotionalMaterial() {
		detailLabel.text = venue?.promotion?.tagline
        if venue?.promotion?.placement > 0 {
            contentView.superview?.backgroundColor = UIColor(red: 251/255, green: 176/255, blue: 64/255, alpha: 0.07)
        } else {
           contentView.superview?.backgroundColor = UIColor.whiteColor()
        }
	}

	func updateVitalityDisplay() {
		if let venue = venue {
			var vitality = ""
			switch venue.vitality {
			case 0:
				vitality = "🎈"
			case 1...5:
				vitality = "💃🏻"
			default:
				vitality = "🔥"
			}

			vitalityDot.text = vitality
			updateVitalityTime()
		}
	}

	func updateVitalityTime() {
		if let time = venue?.samples?.first?.time, calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian) {
			let components = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Hour, NSCalendarUnit.Minute],
				fromDate: time,
				toDate: NSDate(),
				options: [])

            vitalityLabel.text = components.day > 0 ? "\(components.day)d" : components.hour > 0 ? "\(components.hour)h" : components.minute > 0 ? "\(components.minute)m" : "<1m"
		} else {
			vitalityLabel.text = ""
		}
	}
}
