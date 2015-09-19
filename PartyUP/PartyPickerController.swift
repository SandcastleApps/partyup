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

	private var parties: [Party] = [] {
		didSet {
			partyTable.reloadData()
			self.refreshControl?.endRefreshing()
		}
	}

	private var venues: [Venue] = []

	private var attendingIndex: Int? = 0
	private var sampleCount: UInt16 = 0

	private let locationManager: CLLocationManager = {
		let manager = CLLocationManager()
		manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
		return manager
	}()

	private var location: CLLocation?

	@IBOutlet var partyTable: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

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
//		locationManager.stopMonitoringSignificantLocationChanges()
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return .LightContent
	}

	func fetchPartyList() {
		AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper().scan(Party.self, expression: AWSDynamoDBScanExpression()).continueWithBlock { (task) in
			if let error = task.error {
				NSLog("Scan Error: \(error.description)")
			}

			if let except = task.exception {
				NSLog("Scan Exception: \(except.description)")
			}

			if let result = task.result as? AWSDynamoDBPaginatedOutput {
				var parties: [Party] = []
				if let items = result.items as? [Party] {
					parties = items.sort { $0.startTime!.doubleValue < $1.startTime!.doubleValue }
				}
				dispatch_async(dispatch_get_main_queue()) { self.parties = parties }
			}

			return nil
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
        return parties.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PartyPooper", forIndexPath: indexPath) as! ShindigCell
        cell.title.text = parties[indexPath.row].name

        return cell
	}

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "Sample Segue" {
			let recorderVC = segue.destinationViewController as! SamplingController
			recorderVC.recordingFile = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("media_\(sampleCount).mp4")
		}
    }

	@IBAction func sequeFromSampling(segue: UIStoryboardSegue) {
		//if segue.identifier == "Accept Sample" {
			if let srcVC = segue.sourceViewController as? SamplingController {
				let sample = Sample.generateSample(parties[attendingIndex!].id!.integerValue, comment: srcVC.comment)

				if let outputUrl = srcVC.recordingFile {
					if let transfer = AWSS3TransferUtility.defaultS3TransferUtility() {
						transfer.uploadFile(outputUrl,
							bucket: PartyUpConstants.StorageBucket,
							key: sample.id!.base64EncodedStringWithOptions(.EncodingEndLineWithLineFeed) + "." + outputUrl.pathExtension!,
							contentType: outputUrl.mime,
							expression: nil,
							completionHander: nil).continueWithSuccessBlock({ (task) in return AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper().save(sample) }).continueWithBlock({ (task) in
								if let error = task.error
								{
									NSLog("Sample Submission Error: %@", error)
								}

								if let except = task.exception
								{
									NSLog("Sample Submission Exception: %@", except)
								}

								try! NSFileManager.defaultManager().removeItemAtURL(outputUrl)

								return nil
							})

					}

					}
				}
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
