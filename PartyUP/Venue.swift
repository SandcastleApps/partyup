//
//  Venue.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-15.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import SwiftyJSON
import CoreLocation
import AWSDynamoDB

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

	init(unique: String, open: NSTimeInterval, close: NSTimeInterval, name: String, details: String?, vicinity: String?, location: CLLocation) {
		self.unique = unique
		self.open = open
		self.close = close
		self.name = name
		self.details = details
		self.vicinity = vicinity
		self.location = location
	}

	convenience init(venue: JSON) {
		self.init(
			unique: venue["place_id"].stringValue,
			open: 0,
			close: 0,
			name: venue["name"].stringValue,
			details: nil, //venue["description"].string,
			vicinity: venue["vicinity"].stringValue.componentsSeparatedByString(",").first,
			location: CLLocation(latitude: venue["geometry"]["location"]["lat"].doubleValue, longitude: venue["geometry"]["location"]["lng"].doubleValue)
		)
	}

	func updateVitalitySince(time: NSTimeInterval, withSuppression suppress: Int) {
		let queryInput = AWSDynamoDBQueryInput()
		queryInput.tableName = "Samples"
		queryInput.select = .Count
		queryInput.keyConditionExpression = "#e = :hashval"
		queryInput.filterExpression = "#t > :time"
		queryInput.expressionAttributeNames = ["#e": "event", "#t": "time"]
		queryInput.expressionAttributeValues = [":hashval" : wrapValue(unique)!, ":time" : wrapValue(time)!]

		AWSDynamoDB.defaultDynamoDB().query(queryInput).continueWithBlock { (task) in
			if let result = task.result as? AWSDynamoDBQueryOutput {
				dispatch_async(dispatch_get_main_queue()) { self.vitality = result.count.integerValue }
			}

			return nil
		}
	}

	var debugDescription: String {
		get { return "Unique = \(unique)\nopen = \(open)\nclose = \(close)\nname = \(name)\ndetails = \(details)\nlocation = \(location)" }
	}
}