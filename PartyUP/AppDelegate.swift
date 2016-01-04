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
import Flurry_iOS_SDK

struct PartyUpPreferences
{
	static let VideoQuality = "VideoQuality"
	static let ListingRadius = "ListRadius"
	static let SampleRadius = "SampleRadius"
	static let VenueCategories = "VenueCategories"
	static let StaleSampleInterval = "StaleSampleInterval"
	static let CameraJump = "CameraJump"
	static let StickyTowns = "StickyTowns"
	static let PlayTutorial = "Tutorial"
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

struct FlurryConstants
{
	static let ApplicationIdentifier = "***REMOVED***"
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

		NSSetUncaughtExceptionHandler({
			(error) in Flurry.logError("Uncaught_Exception", message: "Uh oh", exception: error)
		})

		Flurry.setUserID(UIDevice.currentDevice().identifierForVendor?.UUIDString)
		Flurry.startSession(FlurryConstants.ApplicationIdentifier)

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

		application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Sound, .Alert], categories: nil))

		return true
	}

	func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
//		let localNote = UILocalNotification()
//		localNote.alertAction = "find a party"
//		localNote.alertBody = "Let's see what kind of fun we can have and contribute some video on the way!"
//		localNote.fireDate = NSDate(timeIntervalSinceNow: 5)
//		localNote.repeatInterval = .Minute
//		application.scheduleLocalNotification(localNote)
	}

	func application(application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: () -> Void) {

		AWSS3TransferUtility.interceptApplication(application, handleEventsForBackgroundURLSession: AwsConstants.BackgroundSession, completionHandler: completionHandler)
	}

}

