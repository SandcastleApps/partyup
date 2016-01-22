//
//  Sample
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-15.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import AWSDynamoDB

enum Vote: Int, CustomDebugStringConvertible {
    case Down = -1, Meh = 0, Up = 1
    
    var debugDescription: String {
        get {
            switch self {
            case Down:
                return "Down"
            case Meh:
                return "Meh"
            case Up:
                return "Up"
            }
        }
    }
}

final class Sample: DynamoObjectWrapper, CustomDebugStringConvertible
{
	typealias UsageStamp = UInt8

	let user: NSUUID
    let event: String
	let time: NSDate
	var comment: String?
	var rating: [Int]

	var media: NSURL {
		get { return NSURL(fileURLWithPath: user.UUIDString + String(stamp)).URLByAppendingPathExtension("mp4") }
	}

	var identifier: NSData {
		get {
			var raw = Array<UInt8>(count: 17, repeatedValue: stamp)
			user.getUUIDBytes(&raw)
			return NSData(bytes: &raw, length: raw.count)
		}
	}
    
    var vote: Vote? {
        willSet {
            
        }
        didSet {
            print("Vote: \(vote)", terminator: "\n")
        }
    }

    init(user: NSUUID, event: String, time: NSDate, comment: String?, stamp: UsageStamp, rating: [Int]) {
		self.user = user
        self.event = event
		self.time = time
		self.comment = comment
		self.stamp = stamp
		self.rating = rating
        
        AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper().load(VoteDB.self, hashKey: VoteDB.hashKeyGenerator(event, sample: identifier), rangeKey: VoteDB.rangeKeyGenerator(UIDevice.currentDevice().identifierForVendor!)).continueWithBlock { task in
            guard task.error == nil else { return nil }
            guard task.exception == nil else {return nil }
            
            if let result = task.result as? VoteDB {
                dispatch_async(dispatch_get_main_queue()) { self.vote = Vote(rawValue: result.vote?.integerValue ?? 0) }
            }
            
            return nil
        }
	}

    convenience init(event: String, comment: String? = nil) {
		self.init(
			user: UIDevice.currentDevice().identifierForVendor!,
            event: event,
			time: NSDate(),
			comment: comment,
			stamp: StampFactory.stamper,
			rating: [0,0]
		)

		StampFactory.stamper = StampFactory.stamper &+ 1
	}

	var debugDescription: String {
		get { return "User = \(user.UUIDString) stamp = \(stamp)\nEvent = \(event)\nTimestamp = \(time)\nComment = \(comment)\nRating = \(rating)\n" }
	}

	func updateRating(upDelta up: Int, downDelta down: Int) {
		if let hash = wrapValue(event), range = wrapValue(identifier), up = wrapValue(up), down = wrapValue(down) {
			let updateInput = AWSDynamoDBUpdateItemInput()
			updateInput.tableName = SampleDB.dynamoDBTableName()
			updateInput.key = ["event" : hash, "id" : range]
			updateInput.updateExpression = "SET ups=if_not_exists(ups,:zero)+:up, downs=if_not_exists(downs,:zero)+:down"
            updateInput.expressionAttributeValues = [":up" : up, ":down" : down, ":zero" : wrapValue(0)!]
			updateInput.returnValues = .UpdatedNew
			AWSDynamoDB.defaultDynamoDB().updateItem(updateInput).continueWithBlock { (task) in
				if let error = task.error {
					NSLog("Error updating vote: \(error)")
					return nil
				}
				if let exception = task.exception {
					NSLog("Exception updating vote: \(exception)")
					return nil
				}

				if let result = task.result as? AWSDynamoDBUpdateItemOutput {
                    let rate = [Int(result.attributes["ups"]?.N ?? "0") ?? 0, Int(result.attributes["downs"]?.N ?? "0") ?? 0]
                    dispatch_async(dispatch_get_main_queue()) {
                        self.rating = rate
                    }
				}

				return nil
			}
		}
	}

	//MARK - Internal Dynamo Representation

	internal convenience init(data: SampleDB) {
		self.init(
			user: NSUUID(UUIDBytes: UnsafePointer(data.id!.bytes)),
            event: data.event!,
			time: NSDate(timeIntervalSince1970: data.time!.doubleValue),
			comment: data.comment,
			stamp: (UnsafePointer<UInt8>(data.id!.bytes) + 16).memory,
			rating: [data.ups?.integerValue ?? 0, data.downs?.integerValue ?? 0]
		)
	}

	internal var dynamo: SampleDB {
		get {
			let db = SampleDB()
			db.time = time.timeIntervalSince1970
			db.comment = comment
			db.id = identifier
            db.event = event
			db.ups = rating[0]
			db.downs = rating[1]

			return db
		}
	}

	internal class SampleDB: AWSDynamoDBObjectModel, AWSDynamoDBModeling
	{
		var id: NSData?
		var event: String?
		var time: NSNumber?
		var comment: String?
		var ups: NSNumber?
		var downs: NSNumber?

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

	//MARK - Internal Stamp Factory

	private let stamp: UsageStamp

	private struct StampFactory
	{
		private static let path: String! = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first?.stringByAppendingString("/UsageStamp.dat")
		static var stamper: UsageStamp =
			{ if let raw = NSData(contentsOfFile: path) { return UnsafePointer<UInt8>(raw.bytes).memory } else { return 0 }  }()
			{ didSet { NSData(bytes: &stamper, length: 1).writeToFile(path, atomically: true)} }
	}
    
    //MARK - Internal Dynamo Vote
    
    private class VoteDB: AWSDynamoDBObjectModel, AWSDynamoDBModeling
    {
        var sample: NSData?
        var user: NSData?
        var vote: NSNumber?
        
        @objc static func dynamoDBTableName() -> String {
            return "Votes"
        }
        
        @objc static func hashKeyAttribute() -> String! {
            return "sample"
        }
        
        @objc static func rangeKeyAttribute() -> String! {
            return "user"
        }
        
        static func hashKeyGenerator(event: String, sample: NSData) -> NSData {
            let combined = NSMutableData(data: sample)
            combined.appendData(event.dataUsingEncoding(NSUTF8StringEncoding)!)
            return combined
        }
        
        static func rangeKeyGenerator(user: NSUUID) -> NSData {
            let raw = Array<UInt8>(count: 16, repeatedValue: 0)
            user.getUUIDBytes(UnsafeMutablePointer<UInt8>(raw))
            return NSData(bytes: raw, length: raw.count)
        }
    }
}