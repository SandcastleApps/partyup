//
//  BakeRootController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-11-05.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit
import CoreLocation
import INTULocationManager
import JGProgressHUD
import Flurry_iOS_SDK

class BakeRootController: UIViewController {
	private var recordController: RecordSampleController!
	private var acceptController: AcceptSampleController!
	private let progressHud = JGProgressHUD(style: .Light)

	var venues = [Venue]()

	private var locals: [Venue]!

    override func viewDidLoad() {
        super.viewDidLoad()

		progressHud.delegate = self

		Flurry.logEvent("Entering_Bakery")

		INTULocationManager.sharedInstance().requestLocationWithDesiredAccuracy(.Neighborhood, timeout: 30) { (location, accuracy, status) in
			if status == .Success {
				let radius = NSUserDefaults.standardUserDefaults().doubleForKey(PartyUpPreferences.SampleRadius)
				let locs = self.venues.filter { venue in return location.distanceFromLocation(venue.location) <= radius + location.horizontalAccuracy }.sort { $0.location.distanceFromLocation(location) < $1.location.distanceFromLocation(location) }
				dispatch_async(dispatch_get_main_queue()) { self.collectSample(locs) }
			} else {
				var message = "Unknown Error"
				var hud = true

				switch status {
				case .ServicesRestricted:
					fallthrough
				case .ServicesNotDetermined:
					fallthrough
				case .ServicesDenied:
					message = NSLocalizedString("Please enable \"While Using the App\" location access for PartyUP to submit videos.", comment: "Location services denied alert message while recording")
					hud = false
				case .ServicesDisabled:
					message = NSLocalizedString("Please enable location services to submit videos.", comment: "Location services disabled alert message while recording")
					hud = false
				case .TimedOut:
					message = NSLocalizedString("Timed out determining your location, try again later.", comment: "Location services timeout hud message while recording")
					hud = true
				case .Error:
					message = NSLocalizedString("An unknown location services error occured, sorry about that.", comment: "Location services unknown error hud message while recording")
					hud = true
				case .Success:
					message = NSLocalizedString("Strange, very strange.", comment: "Location services succeeded but we went to error.")
					hud = true
				}
				dispatch_async(dispatch_get_main_queue()) {
					self.locals = [Venue]()

					if hud == true {
						presentResultHud(self.progressHud,
							inView: self.view,
							withTitle: NSLocalizedString("Undetermined Location", comment: "Location determination failure hud title"),
							andDetail: message,
							indicatingSuccess: false)
					} else {
						let alert = UIAlertController(title: NSLocalizedString("Location Services Unavailable", comment: "Location services unavailable alert title"),
							message:message,
							preferredStyle: .Alert)
						alert.addAction(UIAlertAction(title: NSLocalizedString("Roger", comment: "Default location services disabled alert button"), style: .Default, handler: { (action) in self.performSegueWithIdentifier("Sampling Done Segue", sender: nil) }))
						self.presentViewController(alert, animated: true, completion: nil)
					}

					Flurry.logError("Neighborhood_Determination_Failed", message: "Reason \(status)", error: nil)
				}
			}
		}

		recordController = storyboard!.instantiateViewControllerWithIdentifier("RecordSample") as! RecordSampleController
		acceptController = storyboard!.instantiateViewControllerWithIdentifier("AcceptSample") as! AcceptSampleController

		addChildViewController(recordController)
		view.addSubview(recordController.view)
		recordController.transitionStartY = recordController.preview.frame.origin.y
		recordController.didMoveToParentViewController(self)
    }

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		if locals == nil {
			progressHud.textLabel.text = NSLocalizedString("Determining Venue", comment: "Hud title for waiting for location determination")
			progressHud.interactionType = .BlockNoTouches
			progressHud.showInView(view, animated: false)
		}
	}

	func collectSample(filteredVenues: [Venue]) {
		locals = filteredVenues

		if locals.count > 0 {
			recordController.recordButton.enabled = true
			progressHud.dismissAnimated(true);
		} else {
			Flurry.logEvent("Neighborhood_No_Venues")
			presentResultHud(progressHud,
				inView: view,
				withTitle: NSLocalizedString("Unsupported Venue", comment: "Hud title for no nearby venue"),
				andDetail: NSLocalizedString("You are not at a supported venue.", comment: "Hud detail for no nearby venue"),
				indicatingSuccess: false)
		}
	}

	func recordedSample(videoUrl: NSURL?) {
		if let url = videoUrl {
			acceptController.videoUrl = url
			acceptController.venues = locals
			acceptController.transitionStartY = recordController.preview.frame.origin.y
			swapControllers(from: recordController, to: acceptController)
		} else {
			performSegueWithIdentifier("Sampling Done Segue", sender: nil)
		}
	}

	func acceptedSample() {
		performSegueWithIdentifier("Sampling Done Segue", sender: nil)
	}

	func rejectedSample() {
		recordController.transitionStartY = acceptController.review.frame.origin.y
		swapControllers(from: acceptController, to: recordController)
	}

	func swapControllers(from from: UIViewController, to: UIViewController) {
		from.willMoveToParentViewController(nil)
		addChildViewController(to)
		transitionFromViewController(from, toViewController: to, duration: 0.0, options: [], animations: nil) { (done) in
				from.removeFromParentViewController()
				to.didMoveToParentViewController(self)
		}
	}
}

extension BakeRootController: JGProgressHUDDelegate {
	func progressHUD(progressHUD: JGProgressHUD!, didDismissFromView view: UIView!) {
		performSegueWithIdentifier("Sampling Done Segue", sender: nil)
	}
}
