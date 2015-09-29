//
//  Dynamo.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-20.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import AWSDynamoDB
import AWSCore

protocol DynamoObjectWrapper
{
	typealias DynamoRep
	typealias DynamoKey
	init(data: DynamoRep)
	var dynamo: DynamoRep { get }
}

func push<Wrap: DynamoObjectWrapper where Wrap.DynamoRep: AWSDynamoDBObjectModel, Wrap.DynamoRep: AWSDynamoDBModeling, Wrap.DynamoKey: NSObject>(wrapper: Wrap, key: Wrap.DynamoKey) -> AWSTask {
	let db = wrapper.dynamo
	db.setValue(key, forKey: Wrap.DynamoRep.hashKeyAttribute())

	return AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper().save(db)
}

func pull<Wrap: DynamoObjectWrapper where Wrap.DynamoRep == AWSDynamoDBObjectModel>(wrapper: Wrap) {

}

func fetch<Wrap: DynamoObjectWrapper where Wrap.DynamoRep: AWSDynamoDBObjectModel, Wrap.DynamoKey: NSObject>(key: Wrap.DynamoKey, resultBlock: ([Wrap]) -> Void) {
	let query = AWSDynamoDBQueryExpression()
	query.hashKeyValues = key
	AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper().query(Wrap.DynamoRep.self, expression: query).continueWithBlock { (task) in
		guard task.error == nil else { NSLog("Error Fetching \(Wrap.self): \(task.error)"); return nil }
		guard task.exception == nil else { NSLog("Exception Fetching \(Wrap.self): \(task.exception)"); return nil }

		if let result = task.result as? AWSDynamoDBPaginatedOutput {
			if let items = result.items as? [Wrap.DynamoRep] {
				let wraps = items.map { Wrap(data: $0) }
				resultBlock(wraps)
			}
		}

		return nil
	}
}

func fetch<Wrap: DynamoObjectWrapper where Wrap.DynamoRep: AWSDynamoDBObjectModel>(resultBlock: ([Wrap]) -> Void) {
	AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper().scan(Wrap.DynamoRep.self, expression: AWSDynamoDBScanExpression()).continueWithBlock { (task) in
		guard task.error == nil else { NSLog("Error Fetching \(Wrap.self): \(task.error)"); return nil }
		guard task.exception == nil else { NSLog("Exception Fetching \(Wrap.self): \(task.exception)"); return nil }

		if let result = task.result as? AWSDynamoDBPaginatedOutput {
			if let items = result.items as? [Wrap.DynamoRep] {
				let wraps = items.map { Wrap(data: $0) }
				resultBlock(wraps)
			}
		}

		return nil
	}
}