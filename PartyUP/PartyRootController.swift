//
//  PartyRootController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-11-07.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit
import LocationPickerViewController
import INTULocationManager
import CoreLocation
import SCLAlertView
import Flurry_iOS_SDK
import SCLAlertView

class PartyRootController: UIViewController {
	@IBOutlet weak var ackButton: UIButton!
	@IBOutlet weak var reminderButton: UIButton!

	private var partyPicker: PartyPickerController!
	private var here: PartyPlace?
	private var	there: PartyPlace?

	private var adRefreshTimer: NSTimer?
	private var locationRequestId: INTULocationRequestID = 0

	private lazy var stickyTowns: [LocationItem] = {
		var towns = [LocationItem]()
		if let list = NSUserDefaults.standardUserDefaults().arrayForKey(PartyUpPreferences.StickyTowns) {
			for town in list {
				if let town = town as? [NSObject:AnyObject] {
					let address = Address(plist: town)
					let location = LocationItem(coordinate: (address.coordinate.latitude,address.coordinate.longitude), addressDictionary: address.appleAddressDictionary)
					towns.append(location)
				}
			}
		}

		return towns
	}()

    override func viewDidLoad() {
        super.viewDidLoad()

		UIView.animateWithDuration(0.5, delay: 0, options: [.Autoreverse, .Repeat, .AllowUserInteraction], animations: { self.ackButton.alpha = 0.85 }, completion: nil)

		refreshReminderButton()
		resolveLocalPlacemark()

		let nc = NSNotificationCenter.defaultCenter()
		nc.addObserver(self, selector: #selector(PartyRootController.observeApplicationBecameActive), name: UIApplicationDidBecomeActiveNotification, object: nil)
		nc.addObserver(self, selector: #selector(PartyRootController.refreshSelectedRegion), name: PartyPickerController.VenueRefreshRequest, object: nil)
		nc.addObserver(self, selector: #selector(PartyRootController.observeCityUpdateNotification(_:)), name: PartyPlace.CityUpdateNotification, object: nil)
		nc.addObserver(self, selector: #selector(PartyRootController.refreshReminderButton), name: NSUserDefaultsDidChangeNotification, object: nil)

		adRefreshTimer = NSTimer.scheduledTimerWithTimeInterval(3600, target: self, selector: #selector(PartyRootController.refreshAdvertising), userInfo: nil, repeats: true)
    }

	func refreshSelectedRegion(note: NSNotification) {
		if let adjust = note.userInfo?["adjustLocation"] as? Bool where adjust {
			chooseLocation()
		} else {
			fetchPlaceVenues(there)
		}
	}

	func refreshAdvertising() {
		let cities = [here,there].flatMap { $0?.location }
		Advertisement.refresh(cities)
	}

	func resolveLocalPlacemark() {
		partyPicker.isFetching = true

		locationRequestId = INTULocationManager.sharedInstance().requestLocationWithDesiredAccuracy(.City, timeout: 60) { (location, accuracy, status) in
				self.locationRequestId = 0
				if status == .Success {
					Address.addressForCoordinates(location.coordinate) { address, error in
						if let address = address where error == nil {
							self.here = PartyPlace(location: address)
							self.there = self.here
							self.fetchPlaceVenues(self.here)

							Flurry.setLatitude(location!.coordinate.latitude, longitude: location!.coordinate.longitude, horizontalAccuracy: Float(location!.horizontalAccuracy), verticalAccuracy: Float(location!.verticalAccuracy))
						} else {
							self.cancelLocationLookup()
							alertFailureWithTitle(NSLocalizedString("Failed to find you", comment: "Location determination failure hud title"), andDetail: NSLocalizedString("Failed to lookup your city.", comment: "Hud message for failed locality lookup"))
							Flurry.logError("City_Locality_Failed", message: error?.localizedDescription, error: error)
						}
					}
				} else {
					self.cancelLocationLookup()
					alertFailureWithLocationServicesStatus(status)
					Flurry.logError("City_Determination_Failed", message: "Reason \(status.rawValue)", error: nil)
			}
		}
	}

	func cancelLocationLookup() {
		here = nil
		partyPicker.parties = self.there
		partyPicker.isFetching = false
	}

	func fetchPlaceVenues(place: PartyPlace?) {
        if let place = place {
            partyPicker.isFetching = true
            
            if let categories = NSUserDefaults.standardUserDefaults().stringForKey(PartyUpPreferences.VenueCategories) {
                let radius = NSUserDefaults.standardUserDefaults().integerForKey(PartyUpPreferences.ListingRadius)
                place.fetch(radius, categories: categories)
			}
		}
	}

	func refreshReminderButton() {
		if let settings = UIApplication.sharedApplication().currentUserNotificationSettings() where settings.types != .None {
			let defaults = NSUserDefaults.standardUserDefaults()
			reminderButton.hidden = !defaults.boolForKey(PartyUpPreferences.RemindersInterface)

			switch defaults.integerForKey(PartyUpPreferences.RemindersInterval) {
			case 60:
				reminderButton.setTitle("60m 🔔", forState: .Normal)
			case 30:
				reminderButton.setTitle("30m 🔔", forState: .Normal)
			default:
				reminderButton.setTitle("Off 🔕", forState: .Normal)
			}
		}
	}

	func observeCityUpdateNotification(note: NSNotification) {
		if let city = note.object as? PartyPlace {
            partyPicker.isFetching = city.isFetching
            
			if city.lastFetchStatus.error == nil {
				self.partyPicker.parties = self.there
			} else {
				alertFailureWithTitle(NSLocalizedString("Venue Query Failed", comment: "Hud title failed to fetch venues from google"),
					andDetail: NSLocalizedString("The venue query failed.", comment: "Hud detail failed to fetch venues from google"))
			}
		}
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		tutorial.start(self)
	}

	deinit {
		adRefreshTimer?.invalidate()
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

    // MARK: - Navigation

	override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
		if tutorial.tutoring || presentedViewController != nil || navigationController?.topViewController != self {
			return false
		}
		
		if identifier == "Bake Sample Segue" {
            if !AuthenticationManager.shared.isLoggedIn {
				AuthenticationFlow.shared.startOnController(self).addAction { manager in
					if manager.isLoggedIn {
						if self.shouldPerformSegueWithIdentifier("Bake Sample Segue", sender: nil) {
							self.performSegueWithIdentifier("Bake Sample Segue", sender: nil)
						}
					}
				}
                return false
            }
		}

		return true
	}

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "Party Embed Segue" {
			partyPicker = segue.destinationViewController as! PartyPickerController
			partyPicker.parties = nil
		}
		if segue.identifier == "Bake Sample Segue" {
			let bakerVC = segue.destinationViewController as! BakeRootController
			bakerVC.venues = here?.venues.flatMap{ $0 } ?? [Venue]()
			bakerVC.pregame = here?.pregame
		}
	}

	@IBAction func chooseLocation() {
		partyPicker.defocusSearch()
		let locationPicker = LocationPicker()
		let locationNavigator = UINavigationController(rootViewController: locationPicker)
		locationPicker.title = NSLocalizedString("Party Place", comment: "Location picker title")
		locationPicker.searchBarPlaceholder = NSLocalizedString("Search for place or address", comment: "Location picker search bar")
		locationPicker.setColors(UIColor(r: 247, g: 126, b: 86, alpha: 255))
		locationPicker.locationDeniedHandler = { _ in
			var status: INTULocationStatus
			switch INTULocationManager.locationServicesState() {
			case .Denied:
				status = .ServicesDenied
			case .Restricted:
				status = .ServicesRestricted
			case .Disabled:
				status = .ServicesDisabled
			case .NotDetermined:
				status = .ServicesNotDetermined
			case .Available:
				status = .Error
			}
			alertFailureWithLocationServicesStatus(status)
		}
		locationPicker.pickCompletion = { picked in
			let address = Address(coordinate: picked.mapItem.placemark.coordinate, mapkitAddress: picked.addressDictionary!)
			self.there = PartyPlace(location: address)
			if picked.mapItem.isCurrentLocation {
				self.here = self.there
			}
			self.partyPicker.parties = self.there
			self.fetchPlaceVenues(self.there)

			Flurry.logEvent("Selected_Town", withParameters: ["town" : address.debugDescription])
		}
        locationPicker.addButtons(UIBarButtonItem(title: NSLocalizedString("Let's Go!", comment: "Location picker select bar item"), style: .Done, target: nil, action: nil))
		locationPicker.alternativeLocations = stickyTowns
		presentViewController(locationNavigator, animated: true, completion: nil)
	}
	
	@IBAction func setReminders(sender: UIButton) {
		let defaults = NSUserDefaults.standardUserDefaults()
		var interval = defaults.integerForKey(PartyUpPreferences.RemindersInterval)
		interval = (interval + 30) % 90
		defaults.setInteger(interval, forKey: PartyUpPreferences.RemindersInterval)

		refreshReminderButton()

		if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate {
			delegate.scheduleReminders()
		}
	}

	@IBAction func sequeFromBaking(segue: UIStoryboardSegue) {
	}

	@IBAction func segueFromAcknowledgements(segue: UIStoryboardSegue) {
	}

	func observeApplicationBecameActive() {
        let defaults = NSUserDefaults.standardUserDefaults()
        
		if here == nil {
			if INTULocationManager.locationServicesState() == .Available && locationRequestId == 0 {
				resolveLocalPlacemark()
			}
		} else if defaults.boolForKey(PartyUpPreferences.CameraJump) {
			if shouldPerformSegueWithIdentifier("Bake Sample Segue", sender: nil) {
				performSegueWithIdentifier("Bake Sample Segue", sender: nil)
			}
		}
	}
    
    //MARK: - Tutorial
    private enum CoachIdentifier: Int {
        case Greeting = -1000, City = 1001, About, Camera, Reminder
    }
    
    private static let availableCoachMarks = [
        TutorialMark(identifier: CoachIdentifier.Greeting.rawValue, hint: "Welcome to the PartyUP City Hub!\nThis is where you find the parties.\nTap a place to see what is going on!"),
        TutorialMark(identifier: CoachIdentifier.Camera.rawValue, hint: "Take video of your\nnightlife adventures!"),
        TutorialMark(identifier: CoachIdentifier.City.rawValue, hint: "See what is going on in\nother party cities."),
        TutorialMark(identifier: CoachIdentifier.Reminder.rawValue, hint: "You want to remember to PartyUP?\nSet reminders here."),
        TutorialMark(identifier: CoachIdentifier.About.rawValue, hint: "Learn more about PartyUP!")]
    
    private let tutorial = TutorialOverlayManager(marks: PartyRootController.availableCoachMarks)
}
