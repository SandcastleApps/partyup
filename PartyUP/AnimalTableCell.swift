//
//  AnimalTableCell.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-02-03.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//

import UIKit

class AnimalTableCell: UITableViewCell {
	@IBOutlet weak var cityLabel: UILabel!
	@IBOutlet weak var taglineLabel: UILabel!
	@IBOutlet weak var vitalityDot: UILabel!
	@IBOutlet weak var vitalityLabel: UILabel!
	
	var locality: String? {
		didSet {
			let place = locality != nil ? locality! : NSLocalizedString("this hick town", comment: "Default city name in all venues cell")
			cityLabel?.text = NSLocalizedString("All videos in ", comment: "All venues cell title prefix") + place
		}
	}

	var venues: [Venue]? {
		willSet {
			NSNotificationCenter.defaultCenter().removeObserver(self)
		}
		didSet {
			if let venues = venues {
				let nc = NSNotificationCenter.defaultCenter()
				venues.forEach { nc.addObserver(self, selector: Selector("updateVitalityDisplay"), name: Venue.VitalityUpdateNotification, object: $0) }
			}
			updateVitalityDisplay()
		}
	}

	func updateVitalityDisplay() {
		if let venues = venues {
			let videoTotal = venues.reduce(0) { (total, venue) in total + (venue.samples?.count ?? 0) }
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
			taglineLabel.text = NSLocalizedString("\(videoTotal) videos", comment: "All venues cell video count label")
			updateVitalityTime()
		}
	}

	func updateVitalityTime() {
		
	}
}
