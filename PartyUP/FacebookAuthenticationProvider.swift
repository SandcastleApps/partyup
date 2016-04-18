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

    required init(keychain: Keychain) {
		self.keychain = keychain
		self.loginManager = FBSDKLoginManager()
	}

	var isLoggedIn: Bool { return FBSDKAccessToken.currentAccessToken() != nil && keychain[provider] != nil }

    func loginForManager(manager: AuthenticationManager) {
		if FBSDKAccessToken.currentAccessToken() != nil {
			completeLoginForManager(manager, withError: nil)
		} else {
			loginManager.logInWithReadPermissions(nil) { (result: FBSDKLoginManagerLoginResult!, error : NSError!) in
				self.completeLoginForManager(manager, withError: error)
			}
		}
	}

	func logout() {
		loginManager.logOut()
		keychain[provider] = nil
	}

    func resumeSessionForManager(manager: AuthenticationManager) {
		if isLoggedIn {
			completeLoginForManager(manager, withError: nil)
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

	private func completeLoginForManager(manager: AuthenticationManager, withError error: NSError?) {
		if error == nil {
			keychain[provider] = "YES"
			manager.completeLogin([uri : FBSDKAccessToken.currentAccessToken().tokenString], withError: nil)
		} else {
			manager.completeLogin(nil, withError: error)
		}
	}

	private let keychain: Keychain
	private let loginManager: FBSDKLoginManager
}