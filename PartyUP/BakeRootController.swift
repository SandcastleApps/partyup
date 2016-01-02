//
//  BakeRootController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-11-05.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit
import CoreLocation
import SwiftLocation
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

		do {
			try SwiftLocation.shared.currentLocation(.Neighborhood, timeout: 30,
				onSuccess: { (location) in
					if let location = location {
						let radius = NSUserDefaults.standardUserDefaults().doubleForKey(PartyUpPreferences.SampleRadius)
						let locs = self.venues.filter { venue in return location.distanceFromLocation(venue.location) <= radius + location.horizontalAccuracy }.sort { $0.location.distanceFromLocation(location) < $1.location.distanceFromLocation(location) }
						dispatch_async(dispatch_get_main_queue()) { self.collectSample(locs) }
					} else {
						Flurry.logError("Neighborhood_Location_Unspecified", message: "SwiftLocation called onSuccess but provided no location", error: nil)
						dispatch_async(dispatch_get_main_queue()) { self.locals = [Venue](); presentResultHud(self.progressHud,
							inView: self.view,
							withTitle: NSLocalizedString("Undetermined Location", comment: "Hud title for unknown location failure"),
							andDetail: NSLocalizedString("Your location couldn't be determined for unknown reasons.", comment: "Hud detail for location service failure"),
							indicatingSuccess: false)
						}
					}
				},
				onFail: { (error) in
					dispatch_async(dispatch_get_main_queue()) {
						self.locals = [Venue]();
						if let error = error {
							Flurry.logError("Neighborhood_Determination_Failed", message: error.localizedDescription, error: error)
							presentResultHud(self.progressHud,
								inView: self.view,
								withTitle: NSLocalizedString("Undetermined Location", comment: "Hud title for poor location accuracy"),
								andDetail: NSLocalizedString("Your location couldn't be determined with acceptable accuracy.", comment: "Hud detail for poor locaiton accuracy"),
								indicatingSuccess: false)
						}
						
					}
			})
		} catch {
			locals = [Venue]()
			Flurry.logError("Neighborhood_Error_Thrown", message: "The currentLocation call threw an error", error: nil)
			locationServicesUnavailableHandler(NSLocalizedString("You will need to enable location services to submit videos to PartyUP.", comment: "Location services disabled alert message"))
		}

		recordController = storyboard!.instantiateViewControllerWithIdentifier("RecordSample") as! RecordSampleController
		acceptController = storyboard!.instantiateViewControllerWithIdentifier("AcceptSample") as! AcceptSampleController

		addChildViewController(recordController)
		view.addSubview(recordController.view)
		recordController.transitionStartY = recordController.preview.frame.origin.y
		recordController.didMoveToParentViewController(self)
    }

	func locationServicesUnavailableHandler(message: String) {
		let alert = UIAlertController(title: NSLocalizedString("Location Services Disabled", comment: "Location services disabled alert title"),
			message:message,
			preferredStyle: .Alert)
		alert.addAction(UIAlertAction(title: NSLocalizedString("Roger", comment: "Default location services disabled alert button"), style: .Default, handler: nil))
		presentViewController(alert, animated: true, completion: nil)
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
