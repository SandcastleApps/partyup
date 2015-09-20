//
//  Sample
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-15.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import Foundation
import AWSDynamoDB

final class Sample: CustomDebugStringConvertible
{
	typealias UsageStamp = UInt8

	let user: NSUUID
	let time: NSDate
	let comment: String?
	private let stamp: UsageStamp

	private struct StampFactory
	{
		private static let path: String! = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first?.stringByAppendingString("UsageStamp.dat")
		static var stamper: UsageStamp =
			{ if let raw = NSData(contentsOfFile: path) { return UnsafePointer<UInt8>(raw.bytes).memory } else { return 0 }  }()
			{ didSet { NSData(bytes: &stamper, length: 1).writeToFile(path, atomically: true)} }
	}

	var media: NSURL {
		get { return NSURL(fileURLWithPath: identifier.base64EncodedStringWithOptions(.EncodingEndLineWithLineFeed)).URLByAppendingPathExtension("mp4") }
	}

	init(user: NSUUID, time: NSDate, comment: String?, stamp: UsageStamp) {
		self.user = user
		self.time = time
		self.comment = comment
		self.stamp = stamp
	}

	convenience init(comment: String?) {
		self.init(user: UIDevice.currentDevice().identifierForVendor!, time: NSDate(), comment: comment, stamp: StampFactory.stamper)

		StampFactory.stamper = StampFactory.stamper &+ 1
	}

	func push (party: Int) {
		let db = SampleDB()
		db.event = party
		db.time = time.timeIntervalSinceReferenceDate
		db.comment = comment
		db.id = identifier

		AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper().save(db).continueWithBlock { (task) in
			guard task.error == nil else { NSLog("Error Fetching Samples: \(task.error)"); return nil }
			guard task.exception == nil else { NSLog("Exception Fetching Samples: \(task.exception)"); return nil }

			return nil
		}
	}

	static func fetch(party: Int, resultBlock: ([Sample]) -> Void) {
		let expr = AWSDynamoDBQueryExpression()
		expr.hashKeyValues = party
		AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper().query(SampleDB.self, expression: expr).continueWithBlock { (task) in
			guard task.error == nil else { NSLog("Error Fetching Samples: \(task.error)"); return nil }
			guard task.exception == nil else { NSLog("Exception Fetching Samples: \(task.exception)"); return nil }

			if let result = task.result as? AWSDynamoDBPaginatedOutput {
				if let items = result.items as? [SampleDB] {
					let samples = items.map { Sample(data: $0) }
					resultBlock(samples)
				}
			}

			return nil
		}
	}

	var debugDescription: String {
		get { return "User = \(user.UUIDString) stamp = \(stamp)\nTimestamp = \(time)\nComment = \(comment)\n" }
	}

	private init(data: SampleDB) {
		self.user = NSUUID(UUIDBytes: UnsafePointer(data.id!.bytes))
		self.time = NSDate(timeIntervalSinceReferenceDate: data.time!.doubleValue)
		self.comment = data.comment
		self.stamp = (UnsafePointer<UInt8>(data.id!.bytes) + 16).memory
	}

	internal class SampleDB: AWSDynamoDBObjectModel, AWSDynamoDBModeling
	{
		var id: NSData?
		var event: NSNumber?
		var time: NSNumber?
		var comment: String?

		@objc static func dynamoDBTableName() -> String {
			return "Sampler"
		}

		@objc static func hashKeyAttribute() -> String! {
			return "event"
		}

		@objc static func rangeKeyAttribute() -> String! {
			return "id"
		}
	}

	private var identifier: NSData {
		get {
			var raw = Array<UInt8>(count: 17, repeatedValue: stamp)
			UIDevice.currentDevice().identifierForVendor?.getUUIDBytes(&raw)
			return NSData(bytes: &raw, length: raw.count)
		}
	}
}