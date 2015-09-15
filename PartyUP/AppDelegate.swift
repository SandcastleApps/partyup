//
//  AppDelegate.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-13.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit
import AWSCore
import AWSS3

struct PartyUpConstants
{
	static let StorageBucket = "com.sandcastleapps.partyup"
	static let PartyUUID: NSUUID = {
		var uuid: NSUUID!
		let idUrl = try! NSFileManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true).URLByAppendingPathComponent("partyupid.dat")
		if let data = NSData(contentsOfURL: idUrl) {
			uuid = NSUUID(UUIDBytes: UnsafePointer<UInt8>(data.bytes))
		} else {
			uuid = NSUUID()
			var raw = Array<UInt8>(count: 16, repeatedValue: 0)
			uuid.getUUIDBytes(&raw)
			let data = NSData(bytesNoCopy: &raw, length: 16, freeWhenDone: false)
			data.writeToURL(idUrl, atomically: true)
		}

		return uuid
	}()


}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	private struct AwsConstants
	{
		static let RegionType = AWSRegionType.USEast1
		static let IdentityPool = "***REMOVED***"
		static let BackgroundSession = "com.sandcastleapps.partyup.session"
	}

	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

		let credentialProvider = AWSCognitoCredentialsProvider(
			regionType: AwsConstants.RegionType,
			identityPoolId: AwsConstants.IdentityPool)
		let configuration = AWSServiceConfiguration(
			region: AwsConstants.RegionType,
			credentialsProvider: credentialProvider)

		AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration

		return true
	}

	func application(application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: () -> Void) {

		AWSS3TransferUtility.interceptApplication(application, handleEventsForBackgroundURLSession: AwsConstants.BackgroundSession, completionHandler: completionHandler)
	}

}

