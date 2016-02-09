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

	enum PartyTableSection: Int {
		case Animal = 0, Venue = 1
	}

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
		nc.addObserver(self, selector: Selector("updatePromotions:"), name: Venue.PromotionUpdateNotification, object: nil)
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
		(partyTable.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? AnimalTableCell)?.updateVitalityTime()
		partyTable.visibleCells.forEach { ($0 as? VenueTableCell)?.updateVitalityTime() }
	}

	func updatePromotions(note: NSNotification) {
		let oldPlace = (note.userInfo?["old"] as? Promotion)?.placement ?? 0
		if let what = note.object as? Venue, locals = venues {
			var src: Int?
			var dst: Int?
			let whatPlace = what.promotion?.placement ?? 0
			if oldPlace != whatPlace {
				for (index, venue) in locals.enumerate() {
					if venue == what {
						src = index
					} else if dst == nil && (venue.promotion?.placement) ?? 0 <= whatPlace {
						dst = index - (src != nil ? 1 : 0)
					}

					if src != nil && dst != nil {
						break
					}
				}

				if let src = src, dst = dst where src != dst {
					venues?.removeAtIndex(src)
					venues?.insert(what, atIndex: dst)
					partyTable.moveRowAtIndexPath(NSIndexPath(forRow: src, inSection: 1), toIndexPath: NSIndexPath(forRow: dst, inSection: 1))
				}
			}
		}
	}

    // MARK: - Table view data source

	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return section == 0 ? parties?.place.locality : NSLocalizedString("Party Places", comment: "Header for Venues list in  the primary table")
	}

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return section == 0 ? 2 : venues?.count ?? 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		if indexPath.section == 1 {
			let cell = tableView.dequeueReusableCellWithIdentifier("PartyPooper", forIndexPath: indexPath) as! VenueTableCell
			cell.venue = venues?[indexPath.row]
			return cell
		} else {
			let cell = tableView.dequeueReusableCellWithIdentifier("PartyAnimal", forIndexPath: indexPath) as! AnimalTableCell
			cell.locality = parties?.place.locality
			switch indexPath.row {
			case 0:
				cell.title = NSLocalizedString("All party videos in ", comment: "All venues cell title prefix")
				cell.venues = venues
			case 1:
				cell.title = NSLocalizedString("Pregame party videos for ", comment: "Pregame cell title prefix")
				if let pregame = parties?.pregame {
					cell.venues = [pregame]
				} else {
					cell.venues = [Venue]()
				}
			default:
				cell.title = "Your shouldn't see this"
				cell.venues = [Venue]()
			}
			return cell
		}
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
			venues = parties?.venues?.filter{ $0.name.rangeOfString(searchString, options: .CaseInsensitiveSearch) != nil }.sort { $0.promotion?.placement > $1.promotion?.placement }
		} else {
			venues = parties?.venues?.sort { $0.promotion?.placement > $1.promotion?.placement }
		}
	}

    // MARK: - Navigation

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if let selection = (sender as? UITableViewCell).flatMap( {partyTable.indexPathForCell($0)} ) {
			if let viewerVC = segue.destinationViewController as? SampleTastingContoller {
				switch (PartyTableSection(rawValue: selection.section), selection.row) {
				case (.Some(.Venue), let row):
					viewerVC.venues = (venues?[row]).map { [$0] }
					Flurry.logEvent("Venue_Videos", withParameters: ["venue" : venues?[row].name ?? "Mystery Venue"])
				case (.Some(.Animal), 0):
					viewerVC.venues = venues
					Flurry.logEvent("Venue_Videos", withParameters: ["venue" : parties?.place.locality ?? "All"])
				case (.Some(.Animal), 1):
					viewerVC.venues = (parties?.pregame).map { [$0] }
					Flurry.logEvent("Venue_Videos", withParameters: ["venue" : parties?.pregame.name ?? "Pregame"])
				default:
					viewerVC.venues = nil
					Flurry.logError("Invalid_Party_Selection", message: "An invalid selection was made in the party picking table", error: nil)
				}
			}
		}
	}
}
