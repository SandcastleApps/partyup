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

    func loginFromViewController(controller: UIViewController)
	func logout()
}

protocol AuthenticationProviding: AuthenticationProvider {
	var wasLoggedIn: Bool { get }

	init(manager: AuthenticationManaging)

	func resumeSession()

	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
	func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool
}

protocol AuthenticationManaging: class {
	var keychain: Keychain { get }

	func reportLoggedInTokens(logins: [String:AnyObject]?, withError error: NSError?)
	func reportLoggedOutUri(uri: String)
}