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
	@IBOutlet weak var venueLabel: UILabel!
	@IBOutlet weak var detailLabel: UILabel!
	@IBOutlet weak var vitalityLabel: UILabel!

	var venue: Venue? {
		didSet {
			if let venue = venue {
				venueLabel.text = venue.name ?? NSLocalizedString("Mysterious Venue", comment: "Default in cell when venue name is nil")
				dotImage.setImageWithString(venueLabel.text, color: UIColor.orangeColor(), circular:  true)
				detailLabel.text = venue.vicinity
				vitalityLabel.text = String(count: venue.vitality ?? 0, repeatedValue: Character("💃"))
			}
		}
	}

}
