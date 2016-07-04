//
//  Tastable.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-07-03.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//

import Foundation



protocol Tastable: CustomDebugStringConvertible {
	var user: NSUUID { get }
	var alias: String? { get }
	var event: Venue { get }
	var time: NSDate { get }
	var comment: String? { get }
	var media: NSURL { get }
	var debugDescription: String { get }
}

extension Tastable   {
	var debugDescription: String {
		get { return "User = \(user.UUIDString) alias = \(alias)\nEvent = \(event)\nTimestamp = \(time)\nComment = \(comment)\n" }
	}
}