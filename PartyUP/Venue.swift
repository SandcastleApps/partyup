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
	var vitality: Int64?

	init(unique: String, open: NSTimeInterval, close: NSTimeInterval, name: String, details: String?, location: CLLocation) {
		self.unique = unique
		self.open = open
		self.close = close
		self.name = name
		self.details = details
		self.location = location
	}

	init(venue: JSON) {
		self.unique = venue["place_id"].stringValue
		self.open = 0
		self.close = 0
		self.name = venue["name"].stringValue
		self.details = nil //venue["description"].string
		self.location = CLLocation(latitude: venue["geometry"]["location"]["lat"].doubleValue, longitude: venue["geometry"]["location"]["lng"].doubleValue)
	}

	var debugDescription: String {
		get { return "Unique = \(unique)\nopen = \(open)\nclose = \(close)\nname = \(name)\ndetails = \(details)\nlocation = \(location)" }
	}
}