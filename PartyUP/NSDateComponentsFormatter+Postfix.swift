//
//  NSDateComponentsFormatter+Postfix.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-03-25.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//

import Foundation

extension NSDateComponentsFormatter {
    func stringFromDate(startDate: NSDate,
                        toDate endDate: NSDate,
                               classicThreshold classic: NSTimeInterval?,
                                                postfix: Bool = false,
                                                substituteZero zero: String? = nil) -> String? {
        var capped = false
        var interval = endDate.timeIntervalSinceDate(startDate)
        if let classic = classic where interval > classic {
            interval = classic
            capped = true
            if unitsStyle != .Abbreviated {
                return NSLocalizedString("Classic", comment: "Stale time display")
            }
        }
        
        var formatted = stringFromTimeInterval(interval) ?? "?"
		formatted = formatted.characters.split(",").prefixUpTo(self.maximumUnitCount).map { String($0) }.joinWithSeparator(",")
		
        if capped {
            formatted += "+"
        }
        
        if let zero = zero where formatted.hasPrefix("0") {
            formatted = zero
        } else if postfix {
            formatted += NSLocalizedString(" ago", comment:"Samples more than a minute old")
        }
        return formatted
    }
}