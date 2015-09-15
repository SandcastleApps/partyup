//
//  Venue.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-15.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import Foundation
import AWSDynamoDB

class Venue: AWSDynamoDBObjectModel, AWSDynamoDBModeling
{
	var id: NSNumber?
	var openTime: NSNumber?
	var closeTime: NSNumber?
	var name: String?
	var details: String?
	var locationLat: NSNumber?
	var locationLong: NSNumber?
	var autoParty: NSNumber?

	static func dynamoDBTableName() -> String {
		return "Venues"
	}

	static func hashKeyAttribute() -> String! {
		return "id"
	}
}