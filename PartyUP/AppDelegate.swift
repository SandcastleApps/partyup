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
import CoreData

struct PartyUpPreferences
{
	static let ListingRadius = "ListingRadius"
	static let SampleRadius = "SampleRadius"
	static let VenueCategories = "VenueCategories"
}

struct PartyUpConstants
{
	static let StorageKeyPrefix = "media"
	static let ContentDistribution = NSURL(scheme: "http", host: "drh93nkfgtaww.cloudfront.net", path: "/" + StorageKeyPrefix)!
	static let StorageBucket = "com.sandcastleapps.partyup"
	static let TitleLogo: ()->UIImageView = {
		let logoView = UIImageView(image: UIImage(named: "Logo"))
		logoView.contentMode = .ScaleAspectFit
		logoView.bounds = CGRect(x: 0, y: 0, width: 24, height: 40)
		return logoView
	}
}

struct FourSquareConstants
{
	static let identifier = "***REMOVED***"
	static let secret = "***REMOVED***"
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

		window?.tintColor = UIColor.orangeColor()
		UINavigationBar.appearance().backgroundColor = UIColor.whiteColor()
		UINavigationBar.appearance().backIndicatorImage = UIImage(named: "Back")
		UINavigationBar.appearance().backIndicatorTransitionMaskImage = UIImage(named: "Back")
		UINavigationBar.appearance().translucent = false
		UITextView.appearance().tintColor = UIColor.orangeColor()
		UIButton.appearance().tintColor = UIColor.orangeColor()

		if let defaultsUrl = NSBundle.mainBundle().URLForResource("PartyDefaults", withExtension: "plist") {
			if let defaultsDictionary = NSDictionary(contentsOfURL: defaultsUrl) as? [String:AnyObject] {
				NSUserDefaults.standardUserDefaults().registerDefaults(defaultsDictionary)
			}
		}

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

