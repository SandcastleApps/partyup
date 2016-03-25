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
                               classicThreshold classic: Double?,
                                                postfix: Bool = false,
                                                substituteZero zero: Bool = false) -> String? {
        if let stale = classic.flatMap({ NSDate(timeInterval: -$0, sinceDate: endDate) }) where stale.compare(startDate) == .OrderedDescending {
            return NSLocalizedString("Classic", comment: "Stale time display")
        } else {
            var formatted = stringFromDate(startDate, toDate: endDate) ?? "?"
            if zero && formatted.hasPrefix("0") {
                formatted = unitsStyle == .Abbreviated ? formatted.stringByReplacingOccurrencesOfString("0", withString: "<1") : NSLocalizedString("very fresh", comment: "Relative less than a minute old")
            } else if postfix {
                formatted += NSLocalizedString(" ago", comment:"Samples more than a minute old")
            }
            return formatted
        }
    }
}