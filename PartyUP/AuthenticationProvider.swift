//
//  Authenticating.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-04-17.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//

import UIKit
import KeychainAccess

protocol AuthenticationProvider {
	var name: String { get }
    var isLoggedIn: Bool { get }

	func loginForManager(manager: AuthenticationManager)
	func logout()
	func resumeSessionForManager(manager: AuthenticationManager)

	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
	func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool
}