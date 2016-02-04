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

final class Venue: Hashable, CustomDebugStringConvertible
{
	static let VitalityUpdateNotification = "VitalityUpdateNotification"
	static let PromotionUpdateNotification = "PromotionUpdateNotification"

	let unique: String
	let open: NSTimeInterval
	let close: NSTimeInterval
	let name: String
	let details: String?
	let vicinity: String?
	let location: CLLocation
	var promotion: Promotion? {
		didSet {
			if promotion != oldValue {
				NSNotificationCenter.defaultCenter().postNotificationName(Venue.PromotionUpdateNotification, object: self, userInfo: oldValue != nil ?["old" : oldValue!] : nil)
			}
		}
	}
	var samples: [Sample]? {
		didSet {
			NSNotificationCenter.defaultCenter().postNotificationName(Venue.VitalityUpdateNotification, object: self, userInfo: ["old count" : oldValue?.count ?? 0])
		}
	}

	var vitality: Int {
		get {
			return samples?.count ?? 0
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

		fetchPromotion()
		fetchSamples()
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

	func fetchPromotion() {
		AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper().load(Promotion.PromotionDB.self, hashKey: unique, rangeKey: nil).continueWithSuccessBlock{ task in
			if let result = task.result as? Promotion.PromotionDB where result.venue != nil {
				dispatch_async(dispatch_get_main_queue()) { self.promotion = Promotion(data: result, venue: self) }
			} else {
				self.promotion = nil
			}
			
			return nil
		}
	}

	func fetchSamples(
		withStaleInterval stale: NSTimeInterval = NSUserDefaults.standardUserDefaults().doubleForKey(PartyUpPreferences.StaleSampleInterval),
		andSuppression suppress: Int = NSUserDefaults.standardUserDefaults().integerForKey(PartyUpPreferences.SampleSuppressionThreshold)) {

		let time = NSDate().timeIntervalSince1970 - stale
		let query = AWSDynamoDBQueryExpression()
		query.hashKeyValues = unique
		query.filterExpression = "#t > :stale"
		query.expressionAttributeNames = ["#t": "time"]
        query.expressionAttributeValues = [":stale" : NSNumber(double: time)]
		AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper().query(Sample.SampleDB.self, expression: query).continueWithBlock { (task) in
			if let result = task.result as? AWSDynamoDBPaginatedOutput {
				if let items = result.items as? [Sample.SampleDB] {
                    let wraps = items.filter { ($0.ups?.integerValue ?? 0) - ($0.downs?.integerValue ?? 0) > suppress }.map { Sample(data: $0, event: self) }.sort { $0.time.compare($1.time) == .OrderedDescending }
					dispatch_async(dispatch_get_main_queue()) { self.samples = wraps }
				}
			}

			return nil
		}
	}

	var debugDescription: String {
		get { return "Unique = \(unique)\nopen = \(open)\nclose = \(close)\nname = \(name)\ndetails = \(details)\nlocation = \(location)" }
	}

	var hashValue: Int {
		get { return unique.hashValue }
	}
}

func ==(lhs: Venue, rhs: Venue) -> Bool {
	return lhs.unique == rhs.unique
}