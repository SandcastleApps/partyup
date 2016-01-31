//
//  PartyPickerController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-15.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit
import Flurry_iOS_SDK
import CoreLocation

class PartyPickerController: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate {

	static let VenueRefreshRequest = "VenueListRefreshRequest"

	private var venues: [Venue]? {
		didSet {
			partyTable?.reloadData()
		}
	}

	private var venueTotal = 0

	var parties: PartyPlace? {
		didSet {
			if parties !== oldValue || parties?.venues?.count > venueTotal {
				updateSearchResultsForSearchController(searchController)
				venueTotal = parties?.venues?.count ?? 0

				if parties !== oldValue {
					partyTable?.setContentOffset(CGPointZero, animated: false)
				}
			}

			refreshControl?.endRefreshing()
		}
	}

	private var freshTimer: NSTimer?
	private var searchController: UISearchController!

	@IBOutlet var partyTable: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

		searchController = UISearchController(searchResultsController: nil)
		searchController.searchResultsUpdater = self
		searchController.searchBar.delegate = self
		searchController.dimsBackgroundDuringPresentation = false
		searchController.hidesNavigationBarDuringPresentation = false
		searchController.searchBar.sizeToFit()
		searchController.searchBar.searchBarStyle = .Minimal
		tableView.tableHeaderView = searchController.searchBar
		definesPresentationContext = true

		freshTimer = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: Selector("updateFreshnessIndicators"), userInfo: nil, repeats: true)

		let nc = NSNotificationCenter.defaultCenter()
		nc.addObserver(self, selector: Selector("observeApplicationBecameActive"), name: UIApplicationDidBecomeActiveNotification, object: nil)
		nc.addObserver(self, selector: Selector("observeApplicationBecameInactive"), name: UIApplicationDidEnterBackgroundNotification, object: nil)
    }

	deinit {
		freshTimer?.invalidate()
	}

	func observeApplicationBecameActive() {
		freshTimer = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: Selector("updateFreshnessIndicators"), userInfo: nil, repeats: true)
		updateFreshnessIndicators()
	}

	func observeApplicationBecameInactive() {
		freshTimer?.invalidate()
	}

	@IBAction func updateLocalVenues() {
		NSNotificationCenter.defaultCenter().postNotificationName(PartyPickerController.VenueRefreshRequest, object: self)
	}

	func updateFreshnessIndicators() {
		partyTable.visibleCells.forEach { ($0 as? VenueTableCell)?.updateVitalityTime() }
	}

    // MARK: - Table view data source

	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return parties?.place.locality
	}

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return venues?.count ?? 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("PartyPooper", forIndexPath: indexPath) as! VenueTableCell 
		cell.venue = venues?[indexPath.row]
        return cell
	}

	// MARK: - Search

	func cancelSearch() {
		searchController.active = false
		searchBarCancelButtonClicked(searchController.searchBar)
	}

	func defocusSearch() {
		if searchController.searchBar.isFirstResponder() {
			searchController.searchBar.resignFirstResponder()
		}
	}

	func searchBarCancelButtonClicked(searchBar: UISearchBar) {
		if let searchString = searchController.searchBar.text {
			Flurry.logEvent("Venues_Filtered", withParameters: [ "search" : searchString])
		}
		searchBar.searchBarStyle = .Minimal
		venues = parties?.venues
	}

	func updateSearchResultsForSearchController(searchController: UISearchController) {
		if let searchString = searchController.searchBar.text where searchController.active {
			searchController.searchBar.searchBarStyle = .Prominent
			venues = parties?.venues?.filter{ $0.name.rangeOfString(searchString, options: .CaseInsensitiveSearch) != nil }
		} else {
			venues = parties?.venues
		}
	}

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "Sample Tasting Segue" {
			if let selection = partyTable.indexPathForSelectedRow, party = venues?[selection.row] {
				let viewerVC = segue.destinationViewController as! SampleTastingContoller
				viewerVC.venues = [party]
				viewerVC.title = party.name
				Flurry.logEvent("Venue_Videos", withParameters: ["venue" : party.name])
			}
		}
    }
}
