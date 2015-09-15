//
//  Observation.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-15.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import Foundation
import AWSDynamoDB

class Observation: AWSDynamoDBObjectModel, AWSDynamoDBModeling
{
	var id: NSData?
	var event: NSNumber?
	var user: NSData?
	var time: NSNumber?
	var video: String?
	var comment: String?

	static func dynamoDBTableName() -> String {
		return "Observations"
	}

	static func hashKeyAttribute() -> String! {
		return "id"
	}

	static func rangeKeyAttribute() -> String! {
		return "event"
	}
}