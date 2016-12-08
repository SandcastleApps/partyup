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
	@IBOutlet weak var cameraButton: UIButton! {
		didSet {
			cameraButton?.enabled = here != nil
		}
	}
	@IBOutlet weak var reminderButton: UIButton!

	private var partyPicker: PartyPickerController!
    private var here: PartyPlace? {
        didSet {
            cameraButton?.enabled = here != nil
        }
    }
	private var	there: PartyPlace?

	private var adRefreshTimer: NSTimer?
	private var locationRequestId: INTULocationRequestID = 0

	private var favoriting: SCLAlertViewResponder?
	private lazy var stickyTowns: [Address] = {
		let raw = NSUserDefaults.standardUserDefaults().arrayForKey(PartyUpPreferences.StickyTowns)
		let plist = raw as? [[NSObject:AnyObject]]
		return plist?.flatMap { Address(plist: $0) } ?? [Address]()
	}()

    override func viewDidLoad() {
        super.viewDidLoad()

		refreshReminderButton()
		resolveLocalPlacemark()

		let nc = NSNotificationCenter.defaultCenter()
		nc.addObserver(self, selector: #selector(PartyRootController.observeApplicationBecameActive), name: UIApplicationDidBecomeActiveNotification, object: nil)
		nc.addObserver(self, selector: #selector(PartyRootController.refreshSelectedRegion), name: PartyPickerController.VenueRefreshRequest, object: nil)
		nc.addObserver(self, selector: #selector(PartyRootController.observeCityUpdateNotification(_:)), name: PartyPlace.CityUpdateNotification, object: nil)
		nc.addObserver(self, selector: #selector(PartyRootController.refreshReminderButton), name: NSUserDefaultsDidChangeNotification, object: nil)
        nc.addObserverForName(PartyUpConstants.RecordVideoNotification, object: nil, queue: nil) {_ in 
            if self.shouldPerformSegueWithIdentifier("Bake Sample Segue", sender: nil) {
                self.performSegueWithIdentifier("Bake Sample Segue", sender: nil)
            }
        }
		nc.addObserver(self, selector: #selector(PartyRootController.bookmarkLocation), name: PartyUpConstants.FavoriteLocationNotification, object: nil)
		nc.addObserverForName(AuthenticationManager.AuthenticationStatusChangeNotification, object: nil, queue: NSOperationQueue.mainQueue()) { note in
			let defaults = NSUserDefaults.standardUserDefaults()
			if defaults.boolForKey(PartyUpPreferences.PromptAuthentication) {
                if let new = AuthenticationState(rawValue: note.userInfo?["new"] as! Int), let old = AuthenticationState(rawValue: note.userInfo?["old"] as! Int) where new == .Unauthenticated && old == .Transitioning  {
					let flow = AuthenticationFlow.shared
                    let allowPutoff = defaults.boolForKey(PartyUpPreferences.AllowAuthenticationPutoff)
                    flow.setPutoffs( allowPutoff ?
                            [NSLocalizedString("Miss out on Facebook Posts", comment: "First ignore Facebook button")] : [])
					flow.addAction { [weak self] manager, cancelled in
                        if let me = self {
                            if allowPutoff { defaults.setBool(false, forKey: PartyUpPreferences.PromptAuthentication) }
                            me.presentTutorial()
                        }
                    }
					flow.startOnController(self)
				}
			}
        }

		adRefreshTimer = NSTimer.scheduledTimerWithTimeInterval(3600, target: self, selector: #selector(PartyRootController.refreshAdvertising), userInfo: nil, repeats: true)
    }

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		presentTutorial()
	}

	func presentTutorial() {
		if !NSUserDefaults.standardUserDefaults().boolForKey(PartyUpPreferences.PromptAuthentication) {
			tutorial.start(self)
		}
	}

	func refreshSelectedRegion(note: NSNotification) {
		if let adjust = note.userInfo?["adjustLocation"] as? Bool where adjust {
			chooseLocation()
		} else {
            let force = (note.userInfo?["forceUpdate"] as? Bool) ?? false
			if there == nil {
				resolveLocalPlacemark()
			} else {
				fetchPlaceVenues(there, force: force)
			}
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
							if self.there == nil {
								self.there = self.here
							}
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

    func fetchPlaceVenues(place: PartyPlace?, force: Bool = false) {
        if let place = place {
            partyPicker.isFetching = true
            
            if let categories = NSUserDefaults.standardUserDefaults().stringForKey(PartyUpPreferences.VenueCategories) {
                let radius = NSUserDefaults.standardUserDefaults().integerForKey(PartyUpPreferences.ListingRadius)
                place.fetch(radius, categories: categories, force: force)
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

	deinit {
		adRefreshTimer?.invalidate()
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

    // MARK: - Navigation

	override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
		if (tutorial.tutoring || presentedViewController != nil || navigationController?.topViewController != self) && identifier != "Party Embed Segue" {
			return false
		}
		
		if identifier == "Bake Sample Segue" {
            if !AuthenticationManager.shared.isLoggedIn {
				AuthenticationFlow.shared.startOnController(self).addAction { manager, cancelled in
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
	
	@IBAction func favoriteLocation(sender: UILongPressGestureRecognizer) {
		bookmarkLocation()
	}

	func bookmarkLocation() {
		if var place = there?.location where favoriting == nil {
			let alert = SCLAlertView()
			let nameField = alert.addTextField(NSLocalizedString("Location Name", comment: "Favorite location text title"))
			alert.addButton(NSLocalizedString("Add Favorite", comment: "Add favorite location button")) {
				place.identifier = nameField.text
				self.stickyTowns.append(place)
				NSUserDefaults.standardUserDefaults().setObject(self.stickyTowns.map { $0.plist }, forKey: PartyUpPreferences.StickyTowns)
				self.there?.name = place.identifier
				self.partyPicker.locationFavorited()
			}

			favoriting = alert.showEdit(NSLocalizedString("Favorite Location", comment: "Favorite location title"),
			                            subTitle: NSLocalizedString("Add selected location as a favorite.", comment: "Favorite location subtitle"),
			                            closeButtonTitle: NSLocalizedString("Cancel", comment: "Favorite location cancel"),
			                            colorStyle: 0xF45E63)
			favoriting?.setDismissBlock { self.favoriting = nil }
		}
	}

	@IBAction func chooseLocation() {
		partyPicker.defocusSearch()
		let locationPicker = LocationPicker()
		let locationNavigator = UINavigationController(rootViewController: locationPicker)
		locationPicker.title = NSLocalizedString("Popular Party Places", comment: "Location picker title")
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
		locationPicker.pickCompletion = { [weak locationPicker] picked in
            let name : String? = picked.mapItem.phoneNumber == "Yep" ? picked.name : nil
            let address = Address(coordinate: picked.mapItem.placemark.coordinate, mapkitAddress: picked.addressDictionary!, name: name)
			self.there = PartyPlace(location: address)
			if picked.mapItem.name == "No matter where you go, there you are!" {
				self.here = self.there
			}
			self.partyPicker.parties = self.there
			self.fetchPlaceVenues(self.there)

			Flurry.logEvent("Selected_Town", withParameters: ["town" : address.debugDescription])

			locationPicker?.dismissViewControllerAnimated(true, completion: nil)
		}
		locationPicker.selectCompletion = locationPicker.pickCompletion
        locationPicker.alternativeLocationEditable = true
        locationPicker.deleteCompletion = { picked in
            if let index = self.stickyTowns.indexOf({ $0.name == picked.name && ($0.coordinate.latitude == picked.coordinate?.latitude && $0.coordinate.longitude == picked.coordinate?.longitude)}) {
                self.stickyTowns.removeAtIndex(index)
                NSUserDefaults.standardUserDefaults().setObject(self.stickyTowns.map { $0.plist }, forKey: PartyUpPreferences.StickyTowns)
            }
        }
        locationPicker.addBarButtons(UIBarButtonItem(title: "", style: .Done, target: nil, action: nil))
		locationPicker.alternativeLocations = stickyTowns.map {
            let item = LocationItem(coordinate: (latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude), addressDictionary: $0.appleAddressDictionary)
            item.mapItem.phoneNumber = "Yep"
            return item
        }
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

		presentTutorial()
        
		if here == nil {
			if INTULocationManager.locationServicesState() == .Available && locationRequestId == 0 {
				resolveLocalPlacemark()
			}
		} else if defaults.boolForKey(PartyUpPreferences.CameraJump) && AuthenticationManager.shared.isLoggedIn {
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
        TutorialMark(identifier: CoachIdentifier.Greeting.rawValue, hint: NSLocalizedString("Welcome to the PartyUP City Hub!\nThis is where you find the parties.\nTap a place to see what is going on!", comment: "City hub welcome coachmark")),
        TutorialMark(identifier: CoachIdentifier.Camera.rawValue, hint: NSLocalizedString("Take video of your\nnightlife adventures!", comment: "City hub camera coachmark")),
        TutorialMark(identifier: CoachIdentifier.City.rawValue, hint: NSLocalizedString("See what is going on in\nother party cities.", comment: "City hub location selector coachmark")),
        TutorialMark(identifier: CoachIdentifier.Reminder.rawValue, hint: NSLocalizedString("You want to remember to PartyUP?\nSet reminders here.", comment: "City hub reminder button coachmark")),
        TutorialMark(identifier: CoachIdentifier.About.rawValue, hint: NSLocalizedString("Learn more about PartyUP!", comment: "City hub acknowledgements coachmark"))]
    
    private let tutorial = TutorialOverlayManager(marks: PartyRootController.availableCoachMarks)
}
