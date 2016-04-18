//
//  AuthenticationManager.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-04-17.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//

import Foundation
import KeychainAccess
import AWSCore
import AWSCognito

class AuthenticationManager {
	static let LoginCompleteNotification = "LoginCompleteNotification"
	static let LogoutCompleteNotification = "LogoutCompleteNotification"

	static let shared = AuthenticationManager()
    
	var credentialsProvider: AWSCognitoCredentialsProvider?
	let availableAuthenticators: [AuthenticationProvider]
    
    init() {
        availableAuthenticators = [FacebookAuthenticationProvider(keychain: keychain)]
    }
    
	func loginWithAuthenticator(authenticator: AuthenticationProvider) {
		self.authenticator = authenticator
		self.authenticator?.loginForManager(self)
    }
    
    func logout() {
        authenticator?.logout()
        credentialsProvider?.logins = nil
        AWSCognito.defaultCognito().wipe()
        credentialsProvider?.clearKeychain()
		authenticator = nil
    }
    
    func isLoggedIn() -> Bool {
        return authenticator?.isLoggedIn ?? false
    }
    
    func resumeSession() {
		for auth in availableAuthenticators {
			if auth.isLoggedIn {
				authenticator = auth
				authenticator?.resumeSessionForManager(self)
				break
			}
		}

        if self.credentialsProvider == nil {
			self.completeLogin(nil, withError: nil)
        }
    }

	func completeLogin(logins: [NSObject : AnyObject]?, withError error: NSError?) {
		var task: AWSTask?

		if self.credentialsProvider == nil {
			task = self.initialize(logins)
		} else {
			var merged = credentialsProvider?.logins ?? [:]

			if let logins = logins {
				for (key, value) in logins {
					merged[key] = value
				}
				self.credentialsProvider?.logins = merged
			}
			task = self.credentialsProvider?.refresh()
		}

		task?.continueWithBlock { task in
//			dispatch_async(dispatch_get_main_queue()) {
//				let notify = NSNotificationCenter.defaultCenter()
//				if task.error != nil
//				if task.error != nil {
//					notify.postNotificationName(AuthenticationManager.LoginCompleteNotification, object: self, userInfo: [])
//				} else {
//					notify.postNotificationName(AuthenticationManager.LoginCompleteNotification, object: self, userInfo: [])
//				}
			return nil
		}
	}

	// MARK: - Application Delegate Integration

	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		return authenticator?.application(application, didFinishLaunchingWithOptions: launchOptions) ?? false
	}

	func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
		return authenticator?.application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation) ?? false
	}

	// MARK: - Private
    
    private let keychain = Keychain(service: NSBundle.mainBundle().bundleIdentifier!)
    private var authenticator: AuthenticationProvider?

	private struct AwsConstants
	{
		static let RegionType = AWSRegionType.USEast1
		static let IdentityPool = "***REMOVED***"
	}
    
    private func initialize(logins: [NSObject : AnyObject]?) -> AWSTask? {
        credentialsProvider = AWSCognitoCredentialsProvider(
            regionType: AwsConstants.RegionType,
            identityPoolId: AwsConstants.IdentityPool)
        let configuration = AWSServiceConfiguration(
            region: AwsConstants.RegionType,
            credentialsProvider: credentialsProvider)
        
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
        
        return self.credentialsProvider?.getIdentityId()
    }
}