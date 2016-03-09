//
//  Dynamo.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-20.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import AWSDynamoDB
import AWSCore

func wrapValue<T>(value: T) -> AWSDynamoDBAttributeValue? {
	var wrappedValue: AWSDynamoDBAttributeValue? = AWSDynamoDBAttributeValue()

	switch value.self {
	case is NSString:
		wrappedValue!.S = value as? String
	case is NSNumber:
		wrappedValue!.N = "\(value)"
	case is NSData:
		wrappedValue!.B = value as? NSData
	default:
		wrappedValue = nil
	}

	return wrappedValue
}

