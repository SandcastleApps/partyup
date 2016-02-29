//
//  Defensive.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-02-28.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//

import Foundation

class Defensive {

	static let OffensiveMuteUpdateNotification = "OffensiveMuteUpdateNotification"
    
    static let shared = Defensive()

	init() {
        if let input = NSInputStream(URL: Defensive.path) {
            input.open()
            defer { input.close() }
            var raw = [UInt8](count: 16, repeatedValue: 0)
            while input.hasBytesAvailable {
                if input.read(&raw, maxLength: raw.count) == raw.count {
                    muted.insert(NSUUID(UUIDBytes: raw))
                }
            }
        }
	}

	func mute(user: NSUUID) {
        if !muted.contains(user) {
            muted.insert(user)
            
            if let output = NSOutputStream(URL: Defensive.path, append: true) {
                var raw = [UInt8](count: 16, repeatedValue: 0)
                output.open()
                defer { output.close() }
                user.getUUIDBytes(&raw)
                output.write(&raw, maxLength: raw.count)
            }

			NSNotificationCenter.defaultCenter().postNotificationName(Defensive.OffensiveMuteUpdateNotification, object: self, userInfo: ["muted" : user])
        }
	}

	func unmute(user: NSUUID) {
		if muted.contains(user) {
			muted.remove(user)

			if let output = NSOutputStream(URL: Defensive.path, append: false) {
				var raw = [UInt8](count: 16, repeatedValue: 0)
				output.open()
				defer { output.close() }

				for uuid in muted {
					uuid.getUUIDBytes(&raw)
					output.write(&raw, maxLength: raw.count)
				}
			}

			NSNotificationCenter.defaultCenter().postNotificationName(Defensive.OffensiveMuteUpdateNotification, object: self, userInfo: ["unmuted": user])
		}
	}

    func muted(user: NSUUID) -> Bool {
        return muted.contains(user)
    }

	private static let path: NSURL! = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!, isDirectory: true).URLByAppendingPathComponent("MutedUsers.dat")

	private var muted = Set<NSUUID>()
}
