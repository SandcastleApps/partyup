//
//  SampleVote.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-01-15.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
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

final class SampleVote: DynamoObjectWrapper, CustomDebugStringConvertible
{
	let sample: NSData
    let event: String
	let user: NSUUID
	let vote: Vote

    init(sample: NSData, event: String, user: NSUUID, vote: Vote) {
		self.sample = sample
        self.event = event
		self.user = user
		self.vote = vote
	}

    convenience init(sample: NSData, event: String, vote: Vote) {
		self.init(
			sample: sample,
            event: event,
			user: UIDevice.currentDevice().identifierForVendor!,
			vote: vote
		)
	}

	var debugDescription: String {
		get { return "User = \(user.UUIDString)\nSample = \(sample)\nEvent = \(event)\nVote = \(vote)\n" }
	}

	//MARK - Internal Dynamo Representation

	internal convenience init(data: SampleVoteDB) {
        let sample = data.sample!.subdataWithRange(NSRange(location: 0,length: 17))
        let event = String(data: data.sample!.subdataWithRange(NSRange(location: 16, length: data.sample!.length)), encoding: NSUTF8StringEncoding)
		self.init(
			sample: sample,
            event: event!,
			user: NSUUID(UUIDBytes: UnsafePointer(data.user!.bytes)),
			vote: Vote(rawValue: data.vote?.integerValue ?? 0)!
		)
	}

	internal var dynamo: SampleVoteDB {
		get {
			let db = SampleVoteDB()
            let combined = NSMutableData(data: sample)
            combined.appendData(event.dataUsingEncoding(NSUTF8StringEncoding)!)
			db.sample = combined
			let raw = Array<UInt8>(count: 16, repeatedValue: 0)
			user.getUUIDBytes(UnsafeMutablePointer<UInt8>(raw))
			db.user = NSData(bytes: raw, length: raw.count)
			db.vote = NSNumber(integer: vote.rawValue)

			return db
		}
	}

	internal class SampleVoteDB: AWSDynamoDBObjectModel, AWSDynamoDBModeling
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
	}

	typealias DynamoRep = SampleVoteDB
	typealias DynamoKey = NSData
}