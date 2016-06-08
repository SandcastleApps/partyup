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
import SCLAlertView
import Flurry_iOS_SDK

class BakeRootController: UIViewController {
	private var recordController: RecordSampleController!
	private var acceptController: AcceptSampleController!
	private var waiting: SCLAlertViewResponder?

	var venues = [Venue]()
	var pregame: Venue?

	private var locals: [Venue]!
	private let locationRetryMax = 2
    private let locationTimeoutTolerance = [INTULocationAccuracy.Neighborhood,INTULocationAccuracy.Block,INTULocationAccuracy.Block]
	private var locationRequestId: INTULocationRequestID = 0

    override func viewDidLoad() {
        super.viewDidLoad()

		Flurry.logEvent("Entering_Bakery")

		determineLocation(remainingRetries: locationRetryMax)

		recordController = storyboard!.instantiateViewControllerWithIdentifier("RecordSample") as! RecordSampleController
		acceptController = storyboard!.instantiateViewControllerWithIdentifier("AcceptSample") as! AcceptSampleController

		addChildViewController(recordController)
		view.addSubview(recordController.view)
		recordController.transitionStartY = recordController.preview.frame.origin.y
		recordController.didMoveToParentViewController(self)
    }

	deinit {
		INTULocationManager.sharedInstance().cancelLocationRequest(locationRequestId)
	}

	func determineLocation(remainingRetries retry: Int) {
		locationRequestId = INTULocationManager.sharedInstance().requestLocationWithDesiredAccuracy(.House, timeout: 3 * NSTimeInterval(1 + locationRetryMax - retry)) { (location, accuracy, status) in
			if status == .Success || (status == .TimedOut && accuracy.rawValue >= self.locationTimeoutTolerance[retry].rawValue) {
				let radius = NSUserDefaults.standardUserDefaults().doubleForKey(PartyUpPreferences.SampleRadius)
				let locs = self.venues.filter { venue in return location.distanceFromLocation(venue.location) <= radius + location.horizontalAccuracy }.sort { $0.location.distanceFromLocation(location) < $1.location.distanceFromLocation(location) }
				dispatch_async(dispatch_get_main_queue()) { self.collectSample(locs) }
			} else {
				var tries = retry

				switch status {
				case .ServicesRestricted, .ServicesNotDetermined, .ServicesDenied, .ServicesDisabled:
					tries = 0
				default:
					break
				}
				dispatch_async(dispatch_get_main_queue()) {
					if tries > 0 {
						self.determineLocation(remainingRetries: tries - 1)
					} else {
						self.locals = [Venue]()
						self.waiting?.setDismissBlock { }
						self.waiting?.close()
						alertFailureWithLocationServicesStatus(status) { self.performSegueWithIdentifier("Sampling Done Segue", sender: nil) }
						Flurry.logError("Neighborhood_Determination_Failed", message: "Reason \(status.rawValue)", error: nil)
					}
				}
			}
		}
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		if locals == nil {
			waiting = alertWaitWithTitle(andDetail: NSLocalizedString("Determining Venue", comment: "Hud title for waiting for location determination"),
			                             dismissHandler: { self.performSegueWithIdentifier("Sampling Done Segue", sender: nil) })
		}
	}

	func collectSample(filteredVenues: [Venue]) {
		locals = filteredVenues

		if let pregame = pregame {
			locals.append(pregame)
		}

		waiting?.setDismissBlock { }
		waiting?.close()

		if locals.count > 0 {
			recordController.recordButton.enabled = true
		} else {
			Flurry.logEvent("Neighborhood_No_Venues")
			alertFailureWithTitle(NSLocalizedString("Unsupported Venue", comment: "Hud title for no nearby venue"),
			                    andDetail: NSLocalizedString("You are not at a supported venue.", comment: "Hud detail for no nearby venue")) { self.performSegueWithIdentifier("Sampling Done Segue", sender: nil) }
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
