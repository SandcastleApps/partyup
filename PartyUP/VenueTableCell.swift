//
//  VenueTableCell.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-12-29.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit

class VenueTableCell: PartyTableCell {

	override func updateVitalityTime() {
		if let time = venues?.first?.samples?.first?.time, calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian) {
			let components = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Hour, NSCalendarUnit.Minute],
				fromDate: time,
				toDate: NSDate(),
				options: [])

            vitalityLabel.text = components.day > 0 ? "\(components.day)d" : components.hour > 0 ? "\(components.hour)h" : components.minute > 0 ? "\(components.minute)m" : "<1m"
		} else {
			vitalityLabel.text = ""
		}
	}

	override func updateTagline() {
		taglineLabel.text = venues?.first?.promotion?.tagline
		if venues?.first?.promotion?.placement > 0 {
			contentView.superview?.backgroundColor = UIColor(red: 251/255, green: 176/255, blue: 64/255, alpha: 0.07)
		} else {
			contentView.superview?.backgroundColor = UIColor.whiteColor()
		}
	}
}
