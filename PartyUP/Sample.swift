//
//  Sample
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-15.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import Foundation
import AWSDynamoDB

class Sample: AWSDynamoDBObjectModel, AWSDynamoDBModeling
{
	var id: NSData?
	var event: NSNumber?
	var time: NSNumber?
	var comment: String?

//	private static var sampleCount: UInt8 = 0

	static func generateSample(party: Int, comment: String?) -> Sample {
		let sample = Sample()
		sample.event = party
		sample.time = NSDate().timeIntervalSinceReferenceDate
		sample.comment = comment
		var raw = Array<UInt8>(count: 17, repeatedValue: 0)
		UIDevice.currentDevice().identifierForVendor?.getUUIDBytes(&raw)
		raw[16] = 1
		sample.id = NSData(bytes: &raw, length: raw.count)

		return sample
	}

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