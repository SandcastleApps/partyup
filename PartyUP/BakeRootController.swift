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
						dispatch_async(dispatch_get_main_queue()) { self.collectSample(locs) }
					}
				},
				onFail: { (error) in
					dispatch_async(dispatch_get_main_queue()) { self.collectSample([Venue]()) }
			})
		} catch {
			collectSample([Venue]())
		}

		recordController = storyboard!.instantiateViewControllerWithIdentifier("RecordSample") as! RecordSampleController
		acceptController = storyboard!.instantiateViewControllerWithIdentifier("AcceptSample") as! AcceptSampleController

		addChildViewController(recordController)
		view.addSubview(recordController.view)
		recordController.transitionStartY = recordController.preview.frame.origin.y
		recordController.didMoveToParentViewController(self)
    }

	func collectSample(filteredVenues: [Venue]) {
		locals = filteredVenues

		if locals.count > 0 {
			recordController.recordButton.enabled = true
		} else {
			let alert = UIAlertController(title: "Unsupported Venue", message: "The ability to record a video is unavalable because you are not at a supported venue.", preferredStyle: UIAlertControllerStyle.Alert)
			alert.addAction(UIAlertAction(title: "Rats!", style: .Default, handler: { (action) in self.performSegueWithIdentifier("Sampling Done Segue", sender: nil) }))
			presentViewController(alert, animated: true, completion: nil )
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
