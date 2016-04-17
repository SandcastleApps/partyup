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
	static let shared = AuthenticationManager()
    
	var credentialsProvider: AWSCognitoCredentialsProvider?
    
    init() {
        availableAuthenticators = [FacebookAuthenticationProvider(keychain: keychain)]
    }
    
    func loginFromView(theViewController: UIViewController, withCompletionHandler completionHandler: AWSContinuationBlock) {
        self.completionHandler = completionHandler
        self.loginController = theViewController
        self.displayLoginSheet()
    }
    
    func logout(completionHandler: AWSContinuationBlock) {
        authenticator?.logout()
        self.credentialsProvider?.logins = nil
        AWSCognito.defaultCognito().wipe()
        self.credentialsProvider?.clearKeychain()
        AWSTask(result: nil).continueWithBlock(completionHandler)
    }
    
    func isLoggedIn() -> Bool {
        return authenticator?.isLoggedIn ?? false
    }
    
    func resumeSession(completionHandler: AWSContinuationBlock) {
        self.completionHandler = completionHandler
        
        authenticator?.resumeSessionForManager(self)
        
        if self.credentialsProvider == nil {
            self.completeLogin(nil)
        }
    }

	func completeLogin(logins: [NSObject : AnyObject]?) {
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

		task?.continueWithBlock {
			(task: AWSTask!) -> AnyObject! in
			if (task.error != nil) {
				let defaults = NSUserDefaults.standardUserDefaults()
				let currentDeviceToken: NSData? = defaults.objectForKey(AwsConstants.DeviceTokenKey) as? NSData
				var currentDeviceTokenString : String

				if currentDeviceToken != nil {
					currentDeviceTokenString = currentDeviceToken!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength)
				} else {
					currentDeviceTokenString = ""
				}

				if currentDeviceToken != nil && currentDeviceTokenString != defaults.stringForKey(AwsConstants.CognitoDeviceTokenKey) {

					AWSCognito.defaultCognito().registerDevice(currentDeviceToken).continueWithBlock { (task: AWSTask!) -> AnyObject! in
						if (task.error == nil) {
							defaults.setObject(currentDeviceTokenString, forKey: AwsConstants.CognitoDeviceTokenKey)
						}
						return nil
					}
				}
			}
			return task
        }.continueWithBlock(completionHandler!)
	}

	// MARK: - Application Delegate Integration

	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		return authenticator?.application(application, didFinishLaunchingWithOptions: launchOptions) ?? false
	}

	func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
		return authenticator?.application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation) ?? false
	}

	// MARK: - Messaging

	func alert(message: String) {
		let alert = UIAlertController(title: "Error", message: "\(message)", preferredStyle: .Alert)
		let ok = UIAlertAction(title: "Ok", style: .Default) { (alert: UIAlertAction) -> Void in }
		alert.addAction(ok)
		self.loginController?.presentViewController(alert, animated: true, completion: nil)
	}
    
    func displayLoginSheet() {
        let providers = UIAlertController(title: nil, message: "Login With:", preferredStyle: .ActionSheet)
        
        for auth in availableAuthenticators {
            let action = UIAlertAction(title: auth.name, style: .Default) { _ in auth.loginForManager(self) }
            providers.addAction(action)
        }
        
        let action = UIAlertAction(title: "Cancel", style: .Cancel) { _ in
            AWSTask(result: nil).continueWithBlock(self.completionHandler!)
        }
        
        providers.addAction(action)
        
        self.loginController?.presentViewController(providers, animated: true, completion: nil)
    }

	// MARK: - Private
    
    private let keychain = Keychain(service: NSBundle.mainBundle().bundleIdentifier!)
    private var completionHandler: AWSContinuationBlock?
    private var authenticator: AuthenticationProvider?
    private let availableAuthenticators: [AuthenticationProvider]
    private var loginController: UIViewController?

	private struct AwsConstants
	{
		static let RegionType = AWSRegionType.USEast1
		static let IdentityPool = "***REMOVED***"
        static let DeviceTokenKey = "DeviceToken"
        static let CognitoDeviceTokenKey = "CognitoDeviceToken"
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