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

class BakeRootController: UIViewController {
	private var recordController: RecordSampleController!
	private var acceptController: AcceptSampleController!

	var venues: [Venue]?

	private var locals = [Venue]()

    override func viewDidLoad() {
        super.viewDidLoad()

		do {
			try SwiftLocation.shared.currentLocation(.Block, timeout: 20,
				onSuccess: { (location) in
					if let location = location, venues = self.venues {
						let radius = NSUserDefaults.standardUserDefaults().doubleForKey(PartyUpPreferences.SampleRadius)
						let locs = venues.filter { venue in return location.distanceFromLocation(venue.location) <= radius + location.horizontalAccuracy }
						dispatch_async(dispatch_get_main_queue()) { self.locals = locs }
					}
				},
				onFail: { (error) in
					//handle
			})
		} catch {
			//handle error
		}

		recordController = storyboard!.instantiateViewControllerWithIdentifier("RecordSample") as! RecordSampleController
		acceptController = storyboard!.instantiateViewControllerWithIdentifier("AcceptSample") as! AcceptSampleController

		addChildViewController(recordController)
		view.addSubview(recordController.view)
		recordController.didMoveToParentViewController(self)
    }

	func recordedSample(videoUrl: NSURL?) {
		if let url = videoUrl {
			acceptController.videoUrl = url
			acceptController.venues = locals
			swapControllers(from: recordController, to: acceptController)
		} else {
			performSegueWithIdentifier("Sampling Done Segue", sender: nil)
		}
	}

	func acceptedSample() {
		performSegueWithIdentifier("Sampling Done Segue", sender: nil)
	}

	func rejectedSample() {
		swapControllers(from: acceptController, to: recordController)
	}

	func swapControllers(from from: UIViewController, to: UIViewController) {
		from.willMoveToParentViewController(nil)
		addChildViewController(to)
		transitionFromViewController(from, toViewController: to, duration: 0.5, options: .TransitionCrossDissolve, animations: nil) { (done) in
				from.removeFromParentViewController()
				to.didMoveToParentViewController(self)
		}
	}
}
