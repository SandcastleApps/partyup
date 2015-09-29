//
//  PartyPickerController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-15.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit
import AWSDynamoDB
import AWSS3
import CoreLocation

class PartyPickerController: UITableViewController, CLLocationManagerDelegate {

	private var parties: [Party]? {
		didSet {
			partyTable.reloadData()
			self.refreshControl?.endRefreshing()
		}
	}

	private var venues = [Venue]()
	private let sampler = SampleManager()
	private var candidate: SampleManager.SampleSubmission?


	private let locationManager: CLLocationManager = {
		let manager = CLLocationManager()
		manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
		return manager
	}()

	private var location: CLLocation?

	@IBOutlet var partyTable: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

		navigationController?.navigationBar.tintColor = UIColor.whiteColor()

		if CLLocationManager.locationServicesEnabled() {
			locationManager.delegate = self

			if CLLocationManager.authorizationStatus() == .NotDetermined {
				locationManager.requestWhenInUseAuthorization()
			}

			NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidBecomeActiveNotification, object: nil, queue: nil, usingBlock: { (notification) -> Void in
				self.locationManager.startUpdatingLocation()
			})

			NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidEnterBackgroundNotification, object: nil, queue: nil, usingBlock: { (notification) -> Void in
				self.locationManager.stopUpdatingLocation()
			})

			fetchPartyList()
		}
    }

	override func viewWillDisappear(animated: Bool) {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return .LightContent
	}

	@IBAction func fetchPartyList() {
		fetch() { (parties: [Party]) in
			let sorted = parties.sort{ $0.start.compare($1.start) == .OrderedAscending}
			dispatch_async(dispatch_get_main_queue()) { self.parties = sorted }
		}
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return parties?.count ?? 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PartyPooper", forIndexPath: indexPath) as! ShindigCell
        cell.title.text = parties?[indexPath.row].name ?? "Unknown"

        return cell
	}

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "Sample Segue" {
			let recorderVC = segue.destinationViewController as! SamplingController
			candidate = (Sample(comment: nil), (parties?[(sender as? UITableView)?.indexPathForSelectedRow?.row ?? 0].identifier)!)
			recorderVC.recordingFile = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(candidate!.sample.media.path!)
		} else if segue.identifier == "Sample Tasting Segue" {
			if let selection = partyTable.indexPathForSelectedRow, party = parties?[selection.row] {
				let viewerVC = segue.destinationViewController as! SampleTastingContoller
				viewerVC.eventIdentifier = party.identifier
				viewerVC.title = party.name
			}
		}
    }

	@IBAction func sequeFromSampling(segue: UIStoryboardSegue) {
		if segue.identifier == "Accept Sample" {
			if let srcVC = segue.sourceViewController as? SamplingController {
				if let submission = candidate {
					submission.sample.comment = srcVC.comment
					sampler.submit(submission.sample, event: submission.event)
				}
			}
		}
	}

	@IBAction func segueFromTasting(segue: UIStoryboardSegue) {

	}


	// MARK: - Location Servicing

	func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
		if status == .AuthorizedAlways || status == .AuthorizedWhenInUse {
			locationManager.startUpdatingLocation()
		}
	}

	func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		location = locations.last
	}

}
