//
//  Party.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-15.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import Foundation
import AWSDynamoDB

class Party: AWSDynamoDBObjectModel, AWSDynamoDBModeling
{
	var id: NSNumber?
	var startTime: NSNumber?
	var endTime: NSNumber?
	var venue: NSNumber?
	var name: String?
	var details: String?

	static func dynamoDBTableName() -> String {
		return "Parties"
	}

	static func hashKeyAttribute() -> String! {
		return "id"
	}
}