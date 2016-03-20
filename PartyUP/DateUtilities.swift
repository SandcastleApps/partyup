//
//  NSDateFormatter+RelativeFormat.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-01-27.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//

import Foundation

func formatRelativeDateFrom(from: NSDate, toDate to: NSDate = NSDate(), compact: Bool = false, withClassicInterval classic: Double? = nil) -> String {
    var stringy = ""

	if let stale = classic.flatMap({ NSDate(timeInterval: -$0, sinceDate: to) }) where stale.compare(from) == .OrderedDescending {
		stringy = NSLocalizedString("Classic", comment: "Stale time display")
	} else {
		if let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian) {
			let components = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Hour, NSCalendarUnit.Minute],
				fromDate: from,
				toDate: to,
				options: [])

			switch components.day {
			case 1:
				stringy = compact ? "1d " : NSLocalizedString("1 day ", comment: "Relative day, be sure to leave the space at the end")
			case let x where x > 1:
				stringy = compact ? "\(x)d " : NSLocalizedString("\(x) days ", comment: "Relative days, be sure to leave the space at the end")
			default:
				stringy = ""
			}

			switch components.hour {
			case 1:
				stringy += compact ? "1h " : NSLocalizedString("1 hour ", comment: "Relative hour, be sure to leave the space at the end")
			case let x where x > 1:
				stringy += compact ? "\(x)h " : NSLocalizedString("\(x) hours ", comment: "Relative hours, be sure to leave the space at the end")
			default:
				stringy = ""
			}

			switch components.minute {
			case 1:
				stringy += compact ? "1m " : NSLocalizedString("1 minute ", comment: "Relative minute, be sure to leave space at end")
			case let x where x > 1:
				stringy += compact ? "\(x)m " : NSLocalizedString("\(x) minutes ", comment: "Relative minutes, be sure to leave space at end")
			default:
				stringy += ""
			}

			stringy += stringy.isEmpty ? NSLocalizedString("very fresh", comment: "Relative less than a minute old") : NSLocalizedString("ago", comment:"Samples more than a minute old")
		}
	}

    return stringy
}