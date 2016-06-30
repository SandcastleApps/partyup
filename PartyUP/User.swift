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
	var aliases = ["Anonymous Chickenshit"]

	init() {
		refresh()

		NSNotificationCenter.defaultCenter().addObserverForName(FBSDKAccessTokenDidChangeNotification, object: nil, queue: NSOperationQueue.mainQueue()) { _ in self.refresh() }
	}

	func refresh() {
		if let token = FBSDKAccessToken.currentAccessToken() where token.hasGranted("public_profile") {
			FBSDKGraphRequest.init(graphPath: "me", parameters: ["fields":"name"]).startWithCompletionHandler({ (connection, profile, error) in
				if error == nil {
                    if let name = profile["name"] as? String {
                        self.aliases.append(name)
                    }
				}
			})
		}
	}
}