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
	static let VitalityUpdateNotification = "VitalityUpdateNotification"

	let unique: String
	let open: NSTimeInterval
	let close: NSTimeInterval
	let name: String
	let details: String?
	let vicinity: String?
	let location: CLLocation
	var vitality: Int? {
		didSet {
			if oldValue != vitality {
				NSNotificationCenter.defaultCenter().postNotificationName(Venue.VitalityUpdateNotification, object: self)
			}
		}
	}

	init(unique: String, open: NSTimeInterval, close: NSTimeInterval, name: String, details: String?, vicinity: String, location: CLLocation) {
		self.unique = unique
		self.open = open
		self.close = close
		self.name = name
		self.details = details
		self.vicinity = vicinity
		self.location = location
	}

	init(venue: JSON) {
		self.unique = venue["place_id"].stringValue
		self.open = 0
		self.close = 0
		self.name = venue["name"].stringValue
		self.details = nil //venue["description"].string
		self.vicinity = venue["vicinity"].stringValue.componentsSeparatedByString(",").first
		self.location = CLLocation(latitude: venue["geometry"]["location"]["lat"].doubleValue, longitude: venue["geometry"]["location"]["lng"].doubleValue)
	}

	func updateVitalitySince(time: NSTimeInterval) {
		let fil = QueryFilter(field: "time", op: ">", value: NSNumber(double: time))
		count(unique, filter: fil, type: Sample.self) { (count) in dispatch_async(dispatch_get_main_queue()) { self.vitality = count } }
	}

	var debugDescription: String {
		get { return "Unique = \(unique)\nopen = \(open)\nclose = \(close)\nname = \(name)\ndetails = \(details)\nlocation = \(location)" }
	}
}