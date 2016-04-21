//
//  FacebookAuthenticationProvider.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-04-17.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//

import FBSDKCoreKit
import FBSDKLoginKit
import KeychainAccess

class FacebookAuthenticationProvider: AuthenticationProviding {
	var name: String { return "Facebook" }

    required init(manager: AuthenticationManaging) {
		self.owner = manager
		self.loginManager = FBSDKLoginManager()
	}

	var isLoggedIn: Bool {
		return wasLoggedIn && FBSDKAccessToken.currentAccessToken() != nil
	}

	var wasLoggedIn: Bool {
		return owner.keychain[provider] != nil
	}

    func login() {
		if FBSDKAccessToken.currentAccessToken() != nil {
			completeLoginWithError(nil)
		} else {
			loginManager.logInWithReadPermissions(nil) { (result: FBSDKLoginManagerLoginResult!, error : NSError!) in
				self.completeLoginWithError(error)
			}
		}
	}

	func logout() {
		loginManager.logOut()
		owner.keychain[provider] = nil

		owner.reportLoggedOutUri(uri)
	}

    func resumeSession() {
		if isLoggedIn {
			completeLoginWithError(nil)
		}
	}

	// MARK: - Application Delegate Integration

	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
	}

	func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
		return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
	}

	// MARK: - Private

	private var provider: String { return "Facebook" }
	private var uri: String { return "graph.facebook.com" }

	private func completeLoginWithError(error: NSError?) {
		if error == nil {
			owner.keychain[provider] = "YES"
			owner.reportLoggedInTokens([uri : FBSDKAccessToken.currentAccessToken().tokenString], withError: nil)
		} else {
			owner.reportLoggedInTokens(nil, withError: error)
		}
	}

	private unowned var owner: AuthenticationManaging
	private let loginManager: FBSDKLoginManager
}