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

final class SampleVote: DynamoObjectWrapper, CustomDebugStringConvertible
{
	let sample: NSData
	let user: NSUUID
	let vote: Vote

	init(sample: NSData, user: NSUUID, vote: Vote) {
		self.sample = sample
		self.user = user
		self.vote = vote
	}

	convenience init(sample: NSData, vote: Vote) {
		self.init(
			sample: sample,
			user: UIDevice.currentDevice().identifierForVendor!,
			vote: vote
		)
	}

	var debugDescription: String {
		get { return "User = \(user.UUIDString)\nSample = \(sample)\nVote = \(vote)\n" }
	}

	//MARK - Internal Dynamo Representation

	internal convenience init(data: SampleVoteDB) {
		self.init(
			sample: data.sample!,
			user: NSUUID(UUIDBytes: UnsafePointer(data.user!.bytes)),
			vote: Vote(rawValue: data.vote?.integerValue ?? 0)!
		)
	}

	internal var dynamo: SampleVoteDB {
//		get {
//			let db = SampleVoteDB()
//			db.sample = NSData(bytes: sample.bytes, length: sample.)
//			db.user = user
//			db.vote = NSNumber(integer: vote.rawValue)
//
//			return db
//		}
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