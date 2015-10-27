//
//  Venue.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-15.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import SwiftyJSON
import CoreLocation

final class Venue: CustomDebugStringConvertible
{
	let unique: String
	let open: NSTimeInterval
	let close: NSTimeInterval
	let name: String
	let details: String?
	let location: CLLocation

	init(unique: String, open: NSTimeInterval, close: NSTimeInterval, name: String, details: String?, location: CLLocation) {
		self.unique = unique
		self.open = open
		self.close = close
		self.name = name
		self.details = details
		self.location = location
	}

	init(venue: JSON) {
		self.unique = venue["id"].stringValue
		self.open = 0
		self.close = 0
		self.name = venue["name"].stringValue
		self.details = venue["description"].string
		self.location = CLLocation(latitude: venue["location"]["lat"].doubleValue, longitude: venue["location"]["lng"].doubleValue)
	}

	var debugDescription: String {
		get { return "Unique = \(unique)\nopen = \(open)\nclose = \(close)\nname = \(name)\ndetails = \(details)\nlocation = \(location)" }
	}
}