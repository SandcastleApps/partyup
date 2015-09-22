//
//  Venue.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-15.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import Foundation
import AWSDynamoDB
import CoreLocation

final class Venue: DynamoObjectWrapper, CustomDebugStringConvertible
{
	let identifier: Int
	let open: NSTimeInterval
	let close: NSTimeInterval
	let name: String
	let details: String?
	let location: CLLocationCoordinate2D
	let priority: Int

	init(identifier: Int, open: NSTimeInterval, close: NSTimeInterval, name: String, details: String?, location: CLLocationCoordinate2D, priority: Int = 0) {
		self.identifier = identifier
		self.open = open
		self.close = close
		self.name = name
		self.details = details
		self.location = location
		self.priority = priority
	}

	var debugDescription: String {
		get { return "Idenitifer = \(identifier)\nopen = \(open)\nclose = \(close)\nname = \(name)\ndetails = \(details)\nlocation = \(location)\npriority = \(priority)" }
	}

	//MARK - Internal Dynamo Representation

	internal convenience init(data: VenueDB) {
		self.init(
			identifier: data.id!.integerValue,
			open: data.openTime?.doubleValue ?? 0.0,
			close: data.closeTime?.doubleValue ?? 0.0,
			name: data.name ?? "Unknown",
			details: data.details,
			location: CLLocationCoordinate2D(latitude: data.lat?.doubleValue ?? 0.0, longitude: data.lon?.doubleValue ?? 0.0),
			priority: data.priority?.integerValue ?? 0
		)
	}

	internal var dynamo: VenueDB {
		get {
			let db = VenueDB()
			db.id = identifier
			db.openTime = open
			db.closeTime = close
			db.name = name
			db.details = details
			db.lat = location.latitude
			db.lon = location.longitude
			db.priority = priority
			
			return db
		}
	}

	class VenueDB: AWSDynamoDBObjectModel, AWSDynamoDBModeling
	{
		var id: NSNumber?
		var openTime: NSNumber?
		var closeTime: NSNumber?
		var name: String?
		var details: String?
		var lat: NSNumber?
		var lon: NSNumber?
		var priority: NSNumber?

		static func dynamoDBTableName() -> String {
			return "Venues"
		}

		static func hashKeyAttribute() -> String! {
			return "id"
		}
	}

	typealias DynamoRep = VenueDB
	typealias DynamoKey = NSNumber
}