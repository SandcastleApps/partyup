//
//  FacebookAuthenticationProvider.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-04-17.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import KeychainAccess

class FacebookAuthenticationProvider: AuthenticationProvider {
	var name: String { return "Facebook" }
	var provider: String { return "Facebook" }
	var uri: String { return "graph.facebook.com" }

	required init(manager: AuthenticationManager) {
		self.authenticationManager = manager
		self.keychain = manager.keychain
		self.loginManager = FBSDKLoginManager()
	}

	var isLoggedIn: Bool { return FBSDKAccessToken.currentAccessToken() != nil && keychain[provider] != nil }

	func login() {
		if FBSDKAccessToken.currentAccessToken() != nil {
			completeLogin()
		} else {
			loginManager.logInWithReadPermissions(nil) { (result: FBSDKLoginManagerLoginResult!, error : NSError!) -> Void in
				if (error != nil) {
					dispatch_async(dispatch_get_main_queue()) {
						self.authenticationManager.alert("Error logging in with FB: " + error.localizedDescription)
					}
				} else if result.isCancelled {
						//Do nothing
				} else {
					self.completeLogin()
				}
			}
		}
	}

	func logout() {
		loginManager.logOut()
		keychain[provider] = nil
	}

	func reloadSession() {
		if FBSDKAccessToken.currentAccessToken() != nil {
			completeLogin()
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

	private func completeLogin() {
		keychain[provider] = "YES"
		authenticationManager.completeLogin([uri : FBSDKAccessToken.currentAccessToken().tokenString])
	}

	private let keychain: Keychain
	private let loginManager: FBSDKLoginManager
	private let authenticationManager: AuthenticationManager
}