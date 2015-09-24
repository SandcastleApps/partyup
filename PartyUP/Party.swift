//
//  Party.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-15.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import Foundation
import CoreLocation
import AWSDynamoDB

final class Party: DynamoObjectWrapper, CustomDebugStringConvertible
{
	let identifier: Int
	let start: NSDate
	let end: NSDate
	let venue: Venue
	let name: String
	let details: String?
	var samples: [Sample]?

	init(identifier: Int, start: NSDate, end: NSDate, venue: Venue, name: String, details: String?, samples: [Sample]? = nil) {
		self.identifier = identifier
		self.start = start
		self.end = end
		self.venue = venue
		self.name = name
		self.details = details
		self.samples = samples
	}

	func fetchSamples() {
		fetch(identifier) { (samples: [Sample]) in
			dispatch_async(dispatch_get_main_queue()) { self.samples = samples }
		}
	}

	var debugDescription: String {
		get { return "identifier = \(identifier)\nstart = \(start)\nend = \(end)\nvenue = \(venue.identifier)\nname = \(name)\ndetails = \(details)" }
	}


	//MARK - Internal Dynamo Representation

	internal convenience init(data: PartyDB) {
		self.init(
			identifier: data.id!.integerValue,
			start: NSDate(timeIntervalSinceReferenceDate: data.startTime?.doubleValue ?? 0),
			end: NSDate(timeIntervalSinceReferenceDate: data.endTime?.doubleValue ?? 0),
			venue: Venue(identifier: 3, open: 0, close: 0, name: "old triangle", details: nil, location: CLLocationCoordinate2D(latitude: 0,longitude: 0)),
			name: data.name ?? "Unknown",
			details: data.details
		)
	}

	internal var dynamo: PartyDB {
		get {
			let db = PartyDB()
			db.id = identifier
			db.startTime = start.timeIntervalSinceReferenceDate
			db.endTime = end.timeIntervalSinceReferenceDate
			db.venue = venue.identifier
			db.name = name
			db.details = details

			return db
		}
	}

	class PartyDB: AWSDynamoDBObjectModel, AWSDynamoDBModeling
	{
		var id: NSNumber?
		var startTime: NSNumber?
		var endTime: NSNumber?
		var venue: NSNumber?
		var name: String?
		var details: String?

		@objc static func dynamoDBTableName() -> String {
			return "Parties"
		}

		@objc static func hashKeyAttribute() -> String! {
			return "id"
		}
	}

	typealias DynamoRep = PartyDB
	typealias DynamoKey = NSNumber
}