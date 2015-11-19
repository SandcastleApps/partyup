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

class BakeRootController: UIViewController {
	private var recordController: RecordSampleController!
	private var acceptController: AcceptSampleController!
	private let progressHud = JGProgressHUD(style: .Light)

	var venues = [Venue]()

	private var locals: [Venue]!

    override func viewDidLoad() {
        super.viewDidLoad()

		do {
			try SwiftLocation.shared.currentLocation(.Neighborhood, timeout: 30,
				onSuccess: { (location) in
					if let location = location {
						let radius = NSUserDefaults.standardUserDefaults().doubleForKey(PartyUpPreferences.SampleRadius)
						let locs = self.venues.filter { venue in return location.distanceFromLocation(venue.location) <= radius + location.horizontalAccuracy }
						dispatch_async(dispatch_get_main_queue()) { self.collectSample(locs) }
					} else {
						dispatch_async(dispatch_get_main_queue()) { self.locals = [Venue](); self.presentErrorHudWithTitle("Undetermined Location", detail: "Your location couldn't be determined for unknown reasons") { self.performSegueWithIdentifier("Sampling Done Segue", sender: nil) }
						}
					}
				},
				onFail: { (error) in
					dispatch_async(dispatch_get_main_queue()) { self.locals = [Venue](); self.presentErrorHudWithTitle("Undetermined Location", detail: "Your location couldn't be determined with acceptable accuracy.") { self.performSegueWithIdentifier("Sampling Done Segue", sender: nil) }
					}
			})
		} catch {
			locals = [Venue]()
			presentErrorHudWithTitle("Undetermined Location", detail: "Location services are unavailable.") { self.performSegueWithIdentifier("Sampling Done Segue", sender: nil) }
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
			progressHud.textLabel.text = "Determining Venue"
			progressHud.showInView(view, animated: false)
		}
	}

	private func presentErrorHudWithTitle(title: String, detail: String?, action: ()->()?) {
		if progressHud.hidden {
			progressHud.showInView(view, animated: false)
		}

		progressHud.indicatorView = JGProgressHUDErrorIndicatorView()
		progressHud.textLabel.text = title
		progressHud.detailTextLabel.text = detail
		progressHud.dismissAfterDelay(5, animated: true)
		let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(5 * Double(NSEC_PER_SEC)))
		dispatch_after(delay, dispatch_get_main_queue()) { action() }
	}

	func collectSample(filteredVenues: [Venue]) {
		locals = filteredVenues

		if locals.count > 0 {
			recordController.recordButton.enabled = true
			progressHud.dismissAnimated(true);
		} else {
			presentErrorHudWithTitle("Unsupported Venue", detail: "You are not at a supported venue.") { self.performSegueWithIdentifier("Sampling Done Segue", sender: nil) }
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
