//
//  VenueTableCell.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-12-29.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit

class VenueTableCell: UITableViewCell {

	@IBOutlet weak private var dotImage: UIImageView!
	@IBOutlet weak private var venueLabel: UILabel!
	@IBOutlet weak private var detailLabel: UILabel!
	@IBOutlet weak private var vitalityLabel: UILabel!
    
    private struct VenueTableConstants {
        static let VitalityDivisor = 3
        static let VitalityCap = 10
    }

	var venue: Venue? {
		didSet {
			if let venue = venue {
				venueLabel.text = venue.name ?? NSLocalizedString("Mysterious Venue", comment: "Default in cell when venue name is nil")
                let vitality = venue.vitality < VenueTableConstants.VitalityCap ? "\(venue.vitality)" : "🔥"
				dotImage.setImageWithString(vitality, color: UIColor.orangeColor(), circular:  true)
				detailLabel.text = venue.vicinity
                if let time = venue.samples?.first?.time, calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian) {
						let components = calendar.components([NSCalendarUnit.Hour, NSCalendarUnit.Minute],
							fromDate: time,
							toDate: NSDate(),
							options: [])

						vitalityLabel.text = String(format: "%d:%02d", components.hour,components.minute)
                } else {
                    vitalityLabel.text = ""
                }
			}
		}
	}
}
