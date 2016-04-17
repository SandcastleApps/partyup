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

	var keychain = Keychain(service: NSBundle.mainBundle().bundleIdentifier!)
	var completionHandler: AWSContinuationBlock?
	var authenticator: AuthenticationProvider?
	var credentialsProvider: AWSCognitoCredentialsProvider?
	var loginController: UIViewController?

	func login()

	func initialize(logins: [NSObject : AnyObject]?) -> AWSTask? {
		credentialsProvider = AWSCognitoCredentialsProvider(
			regionType: AwsConstants.RegionType,
			identityPoolId: AwsConstants.IdentityPool)
		let configuration = AWSServiceConfiguration(
			region: AwsConstants.RegionType,
			credentialsProvider: credentialsProvider)

		AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration

		return self.credentialsProvider?.getIdentityId()
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
				let currentDeviceToken: NSData? = defaults.objectForKey(Constants.DEVICE_TOKEN_KEY) as? NSData
				var currentDeviceTokenString : String

				if currentDeviceToken != nil {
					currentDeviceTokenString = currentDeviceToken!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength)
				} else {
					currentDeviceTokenString = ""
				}

				if currentDeviceToken != nil && currentDeviceTokenString != defaults.stringForKey(Constants.COGNITO_DEVICE_TOKEN_KEY) {

					AWSCognito.defaultCognito().registerDevice(currentDeviceToken).continueWithBlock { (task: AWSTask!) -> AnyObject! in
						if (task.error == nil) {
							defaults.setObject(currentDeviceTokenString, forKey: Constants.COGNITO_DEVICE_TOKEN_KEY)
						}
						return nil
					}
				}
			}
			return task
			}.continueWithBlock(self.completionHandler)
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

	// MARK: - Private

	private struct AwsConstants
	{
		static let RegionType = AWSRegionType.USEast1
		static let IdentityPool = "***REMOVED***"
	}
}