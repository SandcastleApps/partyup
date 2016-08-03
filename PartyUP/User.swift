//
//  User.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-06-30.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//

import Foundation
import FBSDKCoreKit

class User {
	private(set) var aliases = [String:String]()

	init() {
		fbNotificationToken = NSNotificationCenter.defaultCenter().addObserverForName(FBSDKAccessTokenDidChangeNotification, object: nil, queue: NSOperationQueue.mainQueue()) { [unowned self] note in
			if let user = note.userInfo?[FBSDKAccessTokenDidChangeUserID] as? Bool where user == true {
				self.refresh()
			}
		}
	}

	deinit {
		let _ = fbNotificationToken.flatMap { NSNotificationCenter.defaultCenter().removeObserver($0) }
	}

	func refresh() {
		self.aliases.removeValueForKey("Facebook")
		if let token = FBSDKAccessToken.currentAccessToken() where token.hasGranted("public_profile") {
			FBSDKGraphRequest(graphPath: "me", parameters: ["fields":"name"]).startWithCompletionHandler({ (connection, profile, error) in
				if error == nil {
                    if let name = profile["name"] as? String {
                        self.aliases["Facebook"] = name
                    }
				}
			})
		}
	}

	private var fbNotificationToken: NSObjectProtocol?
}