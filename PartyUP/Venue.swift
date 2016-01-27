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
	var samples: [Sample]? {
		didSet {
			NSNotificationCenter.defaultCenter().postNotificationName(Venue.VitalityUpdateNotification, object: self)
		}
	}

	var vitality: Int {
		get {
			return samples?.count ?? 0
		}
	}

	private var lastSampleRetrieved: [NSObject: AnyObject]?

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

	func fetchSamplesSince(time: NSTimeInterval, withSuppression suppress: Int) {
		let query = AWSDynamoDBQueryExpression()
		query.hashKeyValues = unique
		query.filterExpression = "#t > :stale"
		query.expressionAttributeNames = ["#t": "time"]
        query.expressionAttributeValues = [":stale" : NSNumber(double: time)]
		if let last = lastSampleRetrieved {
			query.exclusiveStartKey = last
		}
		AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper().query(Sample.SampleDB.self, expression: query).continueWithBlock { (task) in
			if let result = task.result as? AWSDynamoDBPaginatedOutput {
				if let items = result.items as? [Sample.SampleDB] {
					if let last = items.last {
						self.lastSampleRetrieved = ["event" : wrapValue(last.event!)!, "id" : wrapValue(last.id!)!]
					}
                    let wraps = items.filter { ($0.ups?.integerValue ?? 0) - ($0.downs?.integerValue ?? 0) > suppress }.map { Sample(data: $0) }.sort { $0.time.compare($1.time) == .OrderedDescending }
					dispatch_async(dispatch_get_main_queue()) { self.samples = wraps + (self.samples ?? []) }
				}
			}

			return nil
		}
	}

	var debugDescription: String {
		get { return "Unique = \(unique)\nopen = \(open)\nclose = \(close)\nname = \(name)\ndetails = \(details)\nlocation = \(location)" }
	}
}