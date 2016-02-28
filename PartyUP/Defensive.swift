//
//  Defensive.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-02-28.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//

import Foundation

class Defensive {

	init() {

	}

	func mute(user: NSUUID) {
		muted.insert(user)
//		var raw = Array<UInt8>(count: 16, repeatedValue: 0)
//		user.getUUIDBytes(&raw)
//		NSData(bytes: &raw, length: raw.count).writeToURL(path, options: )
	}

	private static let path: NSURL! = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!, isDirectory: true).URLByAppendingPathComponent("MutedUsers.dat")

	private var muted = Set<NSUUID>()
}
