//
//  Sampler
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-15.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import Foundation
import AWSDynamoDB

class Sampler: AWSDynamoDBObjectModel, AWSDynamoDBModeling
{
	var id: NSData?
	var event: NSNumber?
	var time: NSNumber?
	var comment: String?

	static func dynamoDBTableName() -> String {
		return "Sampler"
	}

	static func hashKeyAttribute() -> String! {
		return "event"
	}

	static func rangeKeyAttribute() -> String! {
		return "id"
	}
}