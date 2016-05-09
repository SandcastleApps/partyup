//
//  Authenticating.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-04-17.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//

import Foundation
import KeychainAccess

protocol AuthenticationProvider {
	var name: String { get }
	var isLoggedIn: Bool { get }
	var logo: UIImage? { get }
	var color: UIColor { get }
}

typealias LoginReport = ([String:AnyObject]?, NSError?) -> Void

protocol AuthenticationProviding: AuthenticationProvider {
	var wasLoggedIn: Bool { get }

	init(keychain: Keychain)

	func loginFromViewController(controller: UIViewController, completionHander handler: LoginReport)
	func logout()
	func resumeSessionWithCompletionHandler(hander: LoginReport)

	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
	func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool
}