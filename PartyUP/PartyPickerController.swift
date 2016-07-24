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

	private struct PartySections {
		static let animal = 0
		static let venue = 1
	}

	private var venues: [Venue]? {
		didSet {
            venues?.sortInPlace{ $0.promotion?.placement > $1.promotion?.placement }
			tableView?.reloadData()
		}
	}

	private var venueTotal = 0

	var isFetching = false {
        didSet {
            if isFetching != oldValue {
                tableView?.tableFooterView = isFetching ? partyFooters.first : partyFooters.last
            }
        }
    }

	var parties: PartyPlace? {
		didSet {            
			if parties !== oldValue || parties?.venues.count > venueTotal {
				updateSearchResultsForSearchController(searchController)
				venueTotal = parties?.venues.count ?? 0

				if parties !== oldValue {
					tableView?.setContentOffset(CGPointZero, animated: false)
				}

				if let avc = navigationController?.topViewController as? SampleTastingContoller
					where !isFetching && avc.venues == nil {
					avc.venues = venues
				}
			}

			updateFavoriteIndicator()
			refreshControl?.endRefreshing()
		}
	}

	private func updateFavoriteIndicator() {
		if parties?.location.identifier != nil {
			favoriteButton?.tintColor = UIColor(r: 253, g: 189, b: 79, alpha: 255)
		} else {
			favoriteButton?.tintColor = UIColor(r: 234, g: 235, b: 237, alpha: 255)
		}
	}

	func locationFavorited() {
		tableView.reloadData()
		updateFavoriteIndicator()
	}

	private var freshTimer: NSTimer?
	private var searchController: UISearchController!
	@IBOutlet weak var searchView: UIView!
	@IBOutlet weak var favoriteButton: UIButton!

	@IBOutlet var partyHeader: UIView!
    @IBOutlet var partyFooters: [UIView]! {
        didSet {
            partyFooters.forEach { $0.frame.size.height = 150 }
        }
    }
	@IBOutlet weak var footerLabel: UILabel!
	@IBOutlet weak var footerButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
		NSBundle.mainBundle().loadNibNamed("PartyTableFooter", owner: self, options: nil)

		searchController = UISearchController(searchResultsController: nil)
		searchController.searchResultsUpdater = self
		searchController.searchBar.delegate = self
		searchController.dimsBackgroundDuringPresentation = false
		searchController.hidesNavigationBarDuringPresentation = false
		searchController.searchBar.searchBarStyle = .Minimal
        searchController.searchBar.placeholder = NSLocalizedString("Filter Venues", comment: "City hub filter placeholder.")
		partyHeader.frame.size.height = searchController.searchBar.frame.height
		searchView.addSubview(searchController.searchBar)
		tableView.tableHeaderView = partyHeader
		definesPresentationContext = true

		freshTimer = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: #selector(PartyPickerController.updateFreshnessIndicators), userInfo: nil, repeats: true)

		let nc = NSNotificationCenter.defaultCenter()
		nc.addObserver(self, selector: #selector(PartyPickerController.observeApplicationBecameActive), name: UIApplicationDidBecomeActiveNotification, object: nil)
		nc.addObserver(self, selector: #selector(PartyPickerController.observeApplicationBecameInactive), name: UIApplicationDidEnterBackgroundNotification, object: nil)
		nc.addObserver(self, selector: #selector(PartyPickerController.updatePromotions(_:)), name: Venue.PromotionUpdateNotification, object: nil)

		updateFavoriteIndicator()
		updateTableFooter()
    }

	deinit {
		freshTimer?.invalidate()
	}

	func observeApplicationBecameActive() {
		freshTimer = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: #selector(PartyPickerController.updateFreshnessIndicators), userInfo: nil, repeats: true)
		updateFreshnessIndicators()
	}

	func observeApplicationBecameInactive() {
		freshTimer?.invalidate()
	}

	@IBAction func adjustLocation() {
		NSNotificationCenter.defaultCenter().postNotificationName(PartyPickerController.VenueRefreshRequest, object: self, userInfo: ["adjustLocation" : true])
	}

	@IBAction func updateLocalVenues() {
		NSNotificationCenter.defaultCenter().postNotificationName(PartyPickerController.VenueRefreshRequest, object: self, userInfo: ["adjustLocation" : false])
	}

	func updateFreshnessIndicators() {
		tableView.visibleCells.forEach { ($0 as? PartyTableCell)?.updateVitalityTime() }
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
					tableView.moveRowAtIndexPath(NSIndexPath(forRow: src, inSection: 1), toIndexPath: NSIndexPath(forRow: dst, inSection: 1))
				}
			}
		}
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		searchController.searchBar.sizeToFit()
	}

    // MARK: - Table view data source

	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		let head = section == PartySections.animal ? (parties?.name ?? " ") : NSLocalizedString("Party Places", comment: "Header for Venues list in  the primary table")
		return " " + head + " "
	}

	override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
		if let header = view as? UITableViewHeaderFooterView {
			header.textLabel?.textAlignment = .Center
			header.textLabel?.textColor = UIColor.darkTextColor()
			header.textLabel?.backgroundColor = UIColor.whiteColor()
			let gradient: CAGradientLayer = CAGradientLayer()
			gradient.frame = view.bounds.insetBy(dx: 10.0, dy: view.bounds.midY - 1.0)
			gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
			gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
			gradient.colors = [UIColor(r: 251, g: 176, b: 64, alpha: 255).CGColor, UIColor(r: 236, g: 0, b: 140, alpha: 255).CGColor, UIColor(r: 251, g: 176, b: 64, alpha: 255).CGColor]
			header.backgroundView?.backgroundColor = UIColor.whiteColor()
			header.backgroundView?.layer.insertSublayer(gradient, atIndex: 0)
		}
	}

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return section == PartySections.animal ? 2 : venues?.count ?? 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell: PartyTableCell
		if indexPath.section == PartySections.venue {
			cell = tableView.dequeueReusableCellWithIdentifier("PartyPooper", forIndexPath: indexPath) as! VenueTableCell
			if let venue = venues?[indexPath.row] {
				cell.title = venue.name
				cell.venues = [venue]
			}
		} else {
			cell = tableView.dequeueReusableCellWithIdentifier("PartyAnimal", forIndexPath: indexPath) as! AnimalTableCell
			switch indexPath.row {
			case 0:
				cell.title = NSLocalizedString("All Parties", comment: "All venues cell title prefix")
				cell.venues = venues
			case 1:
				cell.title = NSLocalizedString("Pregame Parties", comment: "Pregame cell title prefix")
				if let pregame = parties?.pregame {
					cell.venues = [pregame]
				} else {
					cell.venues = nil
				}
			default:
				cell.title = "Your shouldn't see this"
				cell.venues = nil
			}
		}
		return cell
	}
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = cell as? PartyTableCell {
           cell.taglineLabel.restartLabel()
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
		if let searchString = searchBar.text {
			Flurry.logEvent("Venues_Filtered", withParameters: [ "search" : searchString])
		}
		searchBar.searchBarStyle = .Minimal
	}

	func updateSearchResultsForSearchController(searchController: UISearchController) {
		if let searchString = searchController.searchBar.text where searchController.active {
			venues = parties?.venues.filter{ $0.name.rangeOfString(searchString, options: .CaseInsensitiveSearch) != nil }
		} else {
            venues = parties.flatMap{Array($0.venues)}
		}
	}

    // MARK: - Navigation
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        return !(navigationController?.topViewController is SampleTastingContoller)
    }

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if let selection = (sender as? UITableViewCell).flatMap( {tableView.indexPathForCell($0)} ) {
			if let viewerVC = segue.destinationViewController as? SampleTastingContoller {
				switch (selection.section, selection.row) {
				case (PartySections.venue, let row):
					viewerVC.venues = (venues?[row]).map { [$0] } ?? []
                    viewerVC.ads = (venues?[row]).flatMap { $0.ads } ?? []
					Flurry.logEvent("Venue_Videos", withParameters: ["venue" : venues?[row].name ?? "Mystery Venue"])
				case (PartySections.animal, 0):
					if let parti = parties where !parti.isFetching {
						viewerVC.venues = venues
					}
                    viewerVC.ads = parties?.ads ?? []
					Flurry.logEvent("Venue_Videos", withParameters: ["venue" : parties?.location.city ?? "All"])
				case (PartySections.animal, 1):
					viewerVC.venues = (parties?.pregame).map { [$0] } ?? []
                    viewerVC.ads = (parties?.pregame).flatMap { $0.ads } ?? []
					Flurry.logEvent("Venue_Videos", withParameters: ["venue" : parties?.pregame.name ?? "Pregame"])
				default:
					viewerVC.venues = nil
					Flurry.logError("Invalid_Party_Selection", message: "An invalid selection was made in the party picking table", error: nil)
				}
			}
		}
	}

	@IBAction func segueFromTasting(segue: UIStoryboardSegue) {
		Flurry.logEvent("Returned_From_Tasting")
	}

	@IBAction func favoriteLocation(sender: UIButton) {
		NSNotificationCenter.defaultCenter().postNotificationName(PartyUpConstants.FavoriteLocationNotification, object: self)
	}

	func updateTableFooter() {
		if AuthenticationManager.shared.isLoggedIn {
			footerLabel.text = NSLocalizedString("Love PartyUP?", comment: "Rate PartyUP footer label")
			footerButton.setTitle(NSLocalizedString("Rate it on the App Store", comment: "Rate PartyUP footer button"), forState: .Normal)
			footerButton.addTarget(self, action: #selector(PartyPickerController.ratePartyUp(_:)), forControlEvents: .TouchUpInside)
		} else {
			footerLabel.text = NSLocalizedString("Want more content?", comment: "Login footer label")
			footerButton.setTitle(NSLocalizedString("Login with Facebook", comment: "Login footer button"), forState: .Normal)
			footerButton.addTarget(self, action: #selector(PartyPickerController.promptUserAuthentication(_:)), forControlEvents: .TouchUpInside)		}
	}
    
    @IBAction func ratePartyUp(sender: UIButton) {
        let url = "itms-apps://itunes.apple.com/app/id\(PartyUpConstants.AppleStoreIdentifier)"
        UIApplication.sharedApplication().openURL(NSURL(string: url)!)
    }

	@IBAction func promptUserAuthentication(sender: UIButton) {
		if !AuthenticationManager.shared.isLoggedIn {
			AuthenticationFlow.shared.startOnController(self).addAction { manager in
				if manager.isLoggedIn {
					self.updateTableFooter()
					self.updateLocalVenues()
				}
			}
		}
	}
}
