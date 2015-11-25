//
//  Sample
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-15.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import AWSDynamoDB

final class Sample: DynamoObjectWrapper, CustomDebugStringConvertible
{
	typealias UsageStamp = UInt8

	let user: NSUUID
	let time: NSDate
	var comment: String?

	var media: NSURL {
		get { return NSURL(fileURLWithPath: user.UUIDString + String(stamp)).URLByAppendingPathExtension("mp4") }
	}

	init(user: NSUUID, time: NSDate, comment: String?, stamp: UsageStamp) {
		self.user = user
		self.time = time
		self.comment = comment
		self.stamp = stamp
	}

	convenience init(comment: String? = nil) {
		self.init(
			user: UIDevice.currentDevice().identifierForVendor!,
			time: NSDate(),
			comment: comment,
			stamp: StampFactory.stamper
		)

		StampFactory.stamper = StampFactory.stamper &+ 1
	}

	var debugDescription: String {
		get { return "User = \(user.UUIDString) stamp = \(stamp)\nTimestamp = \(time)\nComment = \(comment)\n" }
	}

	//MARK - Internal Dynamo Representation

	internal convenience init(data: SampleDB) {
		self.init(
			user: NSUUID(UUIDBytes: UnsafePointer(data.id!.bytes)),
			time: NSDate(timeIntervalSince1970: data.time!.doubleValue),
			comment: data.comment,
			stamp: (UnsafePointer<UInt8>(data.id!.bytes) + 16).memory
		)
	}

	internal var dynamo: SampleDB {
		get {
			let db = SampleDB()
			db.time = time.timeIntervalSince1970
			db.comment = comment
			db.id = identifier

			return db
		}
	}

	internal class SampleDB: AWSDynamoDBObjectModel, AWSDynamoDBModeling
	{
		var id: NSData?
		var event: String?
		var time: NSNumber?
		var comment: String?

		@objc static func dynamoDBTableName() -> String {
			return "Samples"
		}

		@objc static func hashKeyAttribute() -> String! {
			return "event"
		}

		@objc static func rangeKeyAttribute() -> String! {
			return "id"
		}
	}

	typealias DynamoRep = SampleDB
	typealias DynamoKey = NSString

	private var identifier: NSData {
		get {
			var raw = Array<UInt8>(count: 17, repeatedValue: stamp)
			UIDevice.currentDevice().identifierForVendor?.getUUIDBytes(&raw)
			return NSData(bytes: &raw, length: raw.count)
		}
	}

	//MARK - Internal Stamp Factory

	private let stamp: UsageStamp

	private struct StampFactory
	{
		private static let path: String! = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first?.stringByAppendingString("/UsageStamp.dat")
		static var stamper: UsageStamp =
			{ if let raw = NSData(contentsOfFile: path) { return UnsafePointer<UInt8>(raw.bytes).memory } else { return 0 }  }()
			{ didSet { NSData(bytes: &stamper, length: 1).writeToFile(path, atomically: true)} }
	}
}