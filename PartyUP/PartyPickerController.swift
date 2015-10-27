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
import CoreLocation

class PartyPickerController: UITableViewController, CLLocationManagerDelegate {

	private var venues: [Venue]? {
		didSet {
			partyTable.reloadData()
			self.refreshControl?.endRefreshing()
		}
	}

	private let locationManager: CLLocationManager = {
		let manager = CLLocationManager()
		return manager
	}()

	@IBOutlet var partyTable: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

		navigationController?.navigationBar.tintColor = UIColor.whiteColor()

		if CLLocationManager.locationServicesEnabled() {
			locationManager.delegate = self

			if CLLocationManager.authorizationStatus() == .NotDetermined {
				locationManager.requestWhenInUseAuthorization()
			}
		}
    }

	override func viewWillDisappear(animated: Bool) {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return .LightContent
	}

	@IBAction func fetchPartyList() {
		if let location = locationManager.location {
			let params = ["ll" : "\(location.coordinate.latitude),\(location.coordinate.longitude)",
				"client_id" : FourSquareConstants.identifier,
				"client_secret" : FourSquareConstants.secret,
				"categoryId" : "4d4b7105d754a06376d81259",
				"v" : "20140118"]

			Alamofire.request(.GET, "https://api.foursquare.com/v2/venues/search", parameters: params).responseJSON { response in
				if response.result.isSuccess {
					var vens = [Venue]()
					let json = JSON(data: response.data!)
					for venue in json["response"]["venues"].arrayValue {
						vens.append(Venue(venue: venue))
					}

					dispatch_async(dispatch_get_main_queue()) {self.venues = vens}
				}
			}
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
        return venues?.count ?? 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PartyPooper", forIndexPath: indexPath) as! ShindigCell
        cell.title.text = venues?[indexPath.row].name ?? "Unknown"

        return cell
	}

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "Bake Sample Segue" {
			let bakerVC = segue.destinationViewController as! RecordSampleController
			locationManager.startUpdatingLocation()
			bakerVC.venues = venues
			bakerVC.locationManager = locationManager
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


	// MARK: - Location Servicing

	func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
		if status == .AuthorizedAlways || status == .AuthorizedWhenInUse {
			locationManager.startUpdatingLocation()
		}
	}

	func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		if let location = manager.location where location.horizontalAccuracy < 1000 {
			fetchPartyList()

			if location.horizontalAccuracy < 10 {
				manager.stopUpdatingLocation()
			}
		}
	}

}
