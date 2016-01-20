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

	return AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper().save(db)
}

func pull<Wrap: DynamoObjectWrapper where Wrap.DynamoRep == AWSDynamoDBObjectModel>(wrapper: Wrap) {

}

struct QueryFilter<T> {
    let field: String
    let op : String
    let value: T
}

func wrapValue<T>(value: T) -> AWSDynamoDBAttributeValue? {
	var wrappedValue: AWSDynamoDBAttributeValue? = AWSDynamoDBAttributeValue()

	switch value.self {
	case is NSString:
		wrappedValue!.S = value as! String
	case is NSNumber:
		wrappedValue!.N = "\(value)"
	case is NSData:
		wrappedValue!.B = value as! NSData
	default:
		wrappedValue = nil
	}

	return wrappedValue
}

func count<Wrap: DynamoObjectWrapper where Wrap.DynamoRep: AWSDynamoDBModeling, Wrap.DynamoKey: NSObject>(key: Wrap.DynamoKey, type: Wrap.Type, resultBlock: (Int) -> Void) {
    count(key, filter: QueryFilter(field: "", op: "", value: 0), type: type, resultBlock: resultBlock)
}

func count<T, Wrap: DynamoObjectWrapper where Wrap.DynamoRep: AWSDynamoDBModeling, Wrap.DynamoKey: NSObject>(key: Wrap.DynamoKey, filter: QueryFilter<T>, type: Wrap.Type, resultBlock: (Int) -> Void) {
    
	if let keyValue = wrapValue(key) {
		let queryInput = AWSDynamoDBQueryInput()
		queryInput.tableName = Wrap.DynamoRep.dynamoDBTableName()
		queryInput.select = .Count
		queryInput.expressionAttributeNames = ["#h" : Wrap.DynamoRep.hashKeyAttribute()]
		queryInput.keyConditionExpression = "#h = :hashval"
		queryInput.expressionAttributeValues = [":hashval" : keyValue]

		if !filter.op.isEmpty {
			if let filterValue = wrapValue(filter.value) {
				queryInput.expressionAttributeNames["#r"] = filter.field
				queryInput.filterExpression = "#r \(filter.op) :rangeval"
				queryInput.expressionAttributeValues[":rangeval"] = filterValue
			}
		}

		AWSDynamoDB.defaultDynamoDB().query(queryInput).continueWithBlock { (task) in
			guard task.error == nil else { NSLog("Error Counting \(Wrap.self): \(task.error)"); return nil }
			guard task.exception == nil else { NSLog("Exception Counting \(Wrap.self): \(task.exception)"); return nil }

			if let result = task.result as? AWSDynamoDBQueryOutput {
				resultBlock(result.count.integerValue)
			}

			return nil
		}
	}
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