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
        static let VitalityCap = 5
    }

	var venue: Venue? {
		didSet {
			if let venue = venue {
				venueLabel.text = venue.name ?? NSLocalizedString("Mysterious Venue", comment: "Default in cell when venue name is nil")
				dotImage.setImageWithString(venueLabel.text, color: UIColor.orangeColor(), circular:  true)
				detailLabel.text = venue.vicinity
                if var vitality = venue.vitality {
                    vitality = vitality / VenueTableConstants.VitalityDivisor + (vitality % VenueTableConstants.VitalityDivisor > 0 ? 1 : 0)
                    vitalityLabel.text = String(count: min(vitality, VenueTableConstants.VitalityCap), repeatedValue: Character("💃"))
				} else {
					vitalityLabel.text = ""
				}
			}
		}
	}
}
