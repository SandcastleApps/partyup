//
//  PartyPickerController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-15.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import SwiftLocation
import CoreLocation
import UIImageView_Letters

class PartyPickerController: UITableViewController {

	private var venues: [Venue]? {
		didSet {
			partyTable.reloadData()
			self.refreshControl?.endRefreshing()
		}
	}

	let partyAlert: UIAlertController = { let alert = UIAlertController(title: "Party Refresh Failed", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
		alert.addAction(UIAlertAction(title: "Rats!", style: .Default, handler: nil))
		return alert
	}()

	private var lastLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), altitude: -1, horizontalAccuracy: -1, verticalAccuracy: -1, course: -1, speed: -1, timestamp: NSDate(timeIntervalSinceReferenceDate: 0))

	@IBOutlet var partyTable: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

		navigationItem.titleView = UIImageView(image: UIImage(named: "Logo"))
		navigationItem.titleView?.bounds = CGRect(x: 0, y: 0, width: 24, height: 30)

		fetchPartyList()
    }

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

	@IBAction func fetchPartyList() {
		do {
			try SwiftLocation.shared.currentLocation(.City, timeout: 20,
				onSuccess: { (location) in dispatch_async(dispatch_get_main_queue()) { self.updatePartyList(location!) } },
				onFail: { (error) in
//					self.refreshControl?.endRefreshing()
//					if !partyAlert.isBeingPresented() {
//						partyAlert.message = "Your location is unknown."
//						presentViewController(partyAlert, animated: true, completion: nil
					})
		} catch {
			refreshControl?.endRefreshing()
			if !partyAlert.isBeingPresented() {
				partyAlert.message = "Your location is unknown."
				presentViewController(partyAlert, animated: true, completion: nil)
			}
		}
	}

	func updatePartyList(location: CLLocation) {
		if location.distanceFromLocation(lastLocation) > 100 || location.timestamp.timeIntervalSinceDate(lastLocation.timestamp) > 60 {
			if let categories = NSUserDefaults.standardUserDefaults().arrayForKey(PartyUpPreferences.VenueCategories) as? [String] {
				let params = ["ll" : "\(location.coordinate.latitude),\(location.coordinate.longitude)",
					"client_id" : FourSquareConstants.identifier,
					"client_secret" : FourSquareConstants.secret,
					"categoryId" : categories.joinWithSeparator(","),
					"v" : "20140118"]

				Alamofire.request(.GET, "https://api.foursquare.com/v2/venues/search", parameters: params)
					.validate()
					.responseJSON { response in
						if response.result.isSuccess {
							var vens = [Venue]()
							let json = JSON(data: response.data!)
							for venue in json["response"]["venues"].arrayValue {
								vens.append(Venue(venue: venue))
							}

							dispatch_async(dispatch_get_main_queue()) {self.venues = vens; self.lastLocation = location}
						} else {
							dispatch_async(dispatch_get_main_queue()) {
								if !self.partyAlert.isBeingPresented() {
									self.partyAlert.message = "Failed to retrieve venues from Foursquare."
									self.presentViewController(self.partyAlert, animated: true, completion: nil)
								}
							}
						}
				}
			}
		} else {
			refreshControl?.endRefreshing()
		}
	}

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return "Venues provided by FourSquare"
	}

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return venues?.count ?? 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PartyPooper", forIndexPath: indexPath)
        cell.textLabel!.text = venues?[indexPath.row].name ?? "Mysterious Venue"
		cell.detailTextLabel!.text = venues?[indexPath.row].details
		cell.imageView?.bounds = CGRect(x: 0, y: 0, width: 50, height: 50)
		cell.imageView?.setImageWithString(cell.textLabel!.text, color: UIColor.orangeColor(), circular:  true)

        return cell
	}

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "Bake Sample Segue" {
			let bakerVC = segue.destinationViewController as! RecordSampleController
			bakerVC.venues = venues
		}
		if segue.identifier == "Sample Tasting Segue" {
			if let selection = partyTable.indexPathForSelectedRow, party = venues?[selection.row] {
				let viewerVC = segue.destinationViewController as! SampleTastingContoller
				viewerVC.partyId = party.unique
				viewerVC.title = party.name
			}
		}
    }

	@IBAction func sequeFromBaking(segue: UIStoryboardSegue) {

	}

	@IBAction func segueFromTasting(segue: UIStoryboardSegue) {

	}
}
