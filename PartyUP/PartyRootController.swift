//
//  PartyRootController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-11-07.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit
import ActionSheetPicker_3_0
import INTULocationManager
import LMGeocoder
import CoreLocation
import JGProgressHUD
import Flurry_iOS_SDK
import Instructions

class PartyRootController: UIViewController {

	@IBOutlet weak var busyIndicator: UIActivityIndicatorView!
	@IBOutlet weak var busyLabel: UILabel!
	@IBOutlet weak var ackButton: UIButton!
	@IBOutlet weak var reminderButton: UIButton!
	
	private let progressHud = JGProgressHUD(style: .Light)

	private var partyPicker: PartyPickerController!
	private var regions: [PartyPlace!] = [nil]
	private var selectedRegion = 0

	private var adRefreshTimer: NSTimer?

	private var coach: CoachMarksController?

    override func viewDidLoad() {
        super.viewDidLoad()

		UIView.animateWithDuration(0.5, delay: 0, options: [.Autoreverse, .Repeat, .AllowUserInteraction], animations: { self.ackButton.alpha = 0.85 }, completion: nil)

		refreshReminderButton()

		resolvePopularPlacemarks()
		resolveLocalPlacemark()

		let nc = NSNotificationCenter.defaultCenter()
		nc.addObserver(self, selector: #selector(PartyRootController.observeApplicationBecameActive), name: UIApplicationDidBecomeActiveNotification, object: nil)
		nc.addObserver(self, selector: #selector(PartyRootController.refreshSelectedRegion), name: PartyPickerController.VenueRefreshRequest, object: nil)
		nc.addObserver(self, selector: #selector(PartyRootController.observeCityUpdateNotification(_:)), name: PartyPlace.CityUpdateNotification, object: nil)
		nc.addObserver(self, selector: #selector(PartyRootController.refreshReminderButton), name: NSUserDefaultsDidChangeNotification, object: nil)

		adRefreshTimer = NSTimer.scheduledTimerWithTimeInterval(3600, target: self, selector: #selector(PartyRootController.refreshAdvertising), userInfo: nil, repeats: true)

		let defaults = NSUserDefaults.standardUserDefaults()
		if defaults.boolForKey(PartyUpPreferences.PlayTutorial) {
			coach = CoachMarksController()
			coach?.dataSource = self
			coach?.allowOverlayTap = true
			coach?.overlayBackgroundColor = UIColor.grayColor().colorWithAlphaComponent(0.4)
			let skip = CoachMarkSkipDefaultView()
			skip.setTitle("Skip", forState: .Normal)
			coach?.skipView = skip
		}
    }

	func refreshSelectedRegion() {
		fetchPlaceVenues(regions[selectedRegion])
	}

	func refreshAdvertising() {
		let cities = regions.map { $0.place }
		Advertisement.refresh(cities)
	}

	func resolvePopularPlacemarks() {
		if let cities = NSUserDefaults.standardUserDefaults().arrayForKey(PartyUpPreferences.StickyTowns) as? [String] {
			var gen = cities.generate()
			func geoHandler(places: [AnyObject]?, error: NSError?) {
				if let place = places?.first as? LMAddress where error == nil {
					self.regions.append(PartyPlace(place: place))
				}
				if let city = gen.next() {
					LMGeocoder().geocodeAddressString(city, service: .GoogleService, completionHandler: geoHandler)
				}
			}
			if let city = gen.next() {
				LMGeocoder().geocodeAddressString(city, service: .GoogleService, completionHandler: geoHandler)
			}
		}
	}

	func resolveLocalPlacemark() {
		busyIndicator.startAnimating()
		busyLabel.text = NSLocalizedString("locating", comment: "Status message in bottom bar while determining user location")

		INTULocationManager.sharedInstance().requestLocationWithDesiredAccuracy(.City, timeout: 60) { (location, accuracy, status) in
				if status == .Success {
					LMGeocoder().reverseGeocodeCoordinate(location.coordinate, service: .AppleService) { (places, error) in
							if let place = places?.first as? LMAddress where error == nil {
								if let index = self.regions.indexOf({ $0?.place.locality == place.locality }) {
										self.regions[0] = self.regions[index]
								} else {
										self.regions[0] = PartyPlace(place: place)
								}
								self.fetchPlaceVenues(self.regions.first!)

								Flurry.setLatitude(location!.coordinate.latitude, longitude: location!.coordinate.longitude, horizontalAccuracy: Float(location!.horizontalAccuracy), verticalAccuracy: Float(location!.verticalAccuracy))
							} else {
								self.handleLocationErrors(true, message: NSLocalizedString("Locality Lookup Failed", comment: "Hud message for failed locality lookup"))
								Flurry.logError("City_Locality_Failed", message: error?.localizedDescription, error: error)
							}
					}
				} else {
					var message = "Unknown Error"
					var hud = true

					switch status {
					case .ServicesRestricted:
						fallthrough
					case .ServicesNotDetermined:
						fallthrough
					case .ServicesDenied:
						message = NSLocalizedString("Please enable \"While Using the App\" location access for PartyUP to see parties near you.", comment: "Location services denied alert message")
						hud = false
					case .ServicesDisabled:
						message = NSLocalizedString("Please enable location services to see parties near you.", comment: "Location services disabled alert message")
						hud = false
					case .TimedOut:
						message = NSLocalizedString("Timed out determining your location, try again later.", comment: "Location services timeout hud message.")
						hud = true
					case .Error:
						message = NSLocalizedString("An unknown location services error occured, sorry about that.", comment: "Location services unknown error hud message")
						hud = true
					case .Success:
						message = NSLocalizedString("Strange, very strange.", comment: "Location services succeeded but we went to error.")
						hud = true
					}

					self.handleLocationErrors(hud, message: message)

					Flurry.logError("City_Determination_Failed", message: "Reason \(status.rawValue)", error: nil)
			}
		}
	}

	func handleLocationErrors(hud: Bool, message: String) {
		dispatch_async(dispatch_get_main_queue()) {
			self.busyIndicator.stopAnimating()
			self.busyLabel.text = ""
			self.regions[0] = nil
			self.partyPicker.parties = self.regions[self.selectedRegion]

			if hud == true {
				presentResultHud(self.progressHud,
					inView: self.view,
					withTitle: NSLocalizedString("Failed to find you", comment: "Location determination failure hud title"),
					andDetail: message,
					indicatingSuccess: false)
			} else {
				let alert = UIAlertController(title: NSLocalizedString("Location Services Unavailable", comment: "Location services unavailable alert title"),
					message:message,
					preferredStyle: .Alert)
				alert.addAction(UIAlertAction(title: NSLocalizedString("Roger", comment: "Default location services disabled alert button"), style: .Default, handler: nil))
				self.presentViewController(alert, animated: true, completion: nil)
			}
		}
	}

	func fetchPlaceVenues(place: PartyPlace!) {
        if let place = place {
            busyIndicator.startAnimating()
            busyLabel.text = NSLocalizedString("fetching", comment: "Status in bottom bar while fetching venues")
            
            if let categories = NSUserDefaults.standardUserDefaults().stringForKey(PartyUpPreferences.VenueCategories) {
                let radius = NSUserDefaults.standardUserDefaults().integerForKey(PartyUpPreferences.ListingRadius)
                place.fetch(radius, categories: categories)
			}
        } else {
            self.partyPicker.parties = self.regions[self.selectedRegion]
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
			if city.lastFetchStatus.error == nil {
				self.partyPicker.parties = self.regions[self.selectedRegion]
			} else {
				presentResultHud(self.progressHud,
					inView: self.view,
					withTitle: NSLocalizedString("Venue Query Failed", comment: "Hud title failed to fetch venues from foursquare"),
					andDetail: NSLocalizedString("The venue query failed.", comment: "Hud detail failed to fetch venues from foursquare"),
					indicatingSuccess: false)
			}

			if !city.isFetching {
				self.busyIndicator.stopAnimating()
				self.busyLabel.text = ""
			}
		}
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		if let coach = coach {
			//NSUserDefaults.standardUserDefaults().setBool(false, forKey: PartyUpPreferences.PlayTutorial)
			coach.startOn(self)
		}
	}

	deinit {
		adRefreshTimer?.invalidate()
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

    // MARK: - Navigation

	override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
		if identifier == "Bake Sample Segue" {
            let defaults = NSUserDefaults.standardUserDefaults()
            if defaults.boolForKey(PartyUpPreferences.AgreedToTerms) == false {
                let file = NSBundle.mainBundle().pathForResource("Conduct", ofType: "txt")
                let conduct = file.flatMap { try? String.init(contentsOfFile: $0) }
                let terms = UIAlertController(
                    title: NSLocalizedString("Rules of Conduct", comment: "Terms alert title"),
                    message: conduct,
                    preferredStyle: .Alert)
                let full = UIAlertAction(
                    title: NSLocalizedString("Read Terms of Service", comment: "Terms alert full terms action"),
                    style: .Default) { _ in UIApplication.sharedApplication().openURL(NSURL(string: "terms.html", relativeToURL: PartyUpConstants.PartyUpWebsite)!) }
                let agree = UIAlertAction(
                    title: NSLocalizedString("Agree To Terms of Service", comment: "Terms alert agree action"),
                    style: .Default) { _ in defaults.setBool(true, forKey: PartyUpPreferences.AgreedToTerms); self.performSegueWithIdentifier(identifier, sender: nil)}
                let cancel = UIAlertAction(
                    title: NSLocalizedString("Let me think about it", comment: "Terms alert cancel action"),
                    style: .Cancel,
                    handler: nil)
                terms.addAction(full)
                terms.addAction(agree)
                terms.addAction(cancel)
                presentViewController(terms, animated: true, completion: nil)
                
                return false
            }
            
			if presentedViewController != nil {
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
			bakerVC.venues = regions.first??.venues.flatMap{ $0 } ?? [Venue]()
			bakerVC.pregame = regions.first??.pregame
		}
	}

	@IBAction func chooseLocation(sender: UIBarButtonItem) {
		partyPicker.defocusSearch()
		let choices = [NSLocalizedString("Here", comment: "The local choice of location")] + regions[1..<regions.endIndex].map { $0.place.locality! }
		ActionSheetStringPicker.showPickerWithTitle(NSLocalizedString("Region", comment: "Title of the region picker"),
			rows: choices,
			initialSelection: 0,
			doneBlock: { (picker, row, value) in
				self.selectedRegion = row
				if row == 0 {
					self.resolveLocalPlacemark()
				} else {
					self.fetchPlaceVenues(self.regions[row])
				}
				Flurry.logEvent("Selected_Town", withParameters: ["town" : choices[row]])
			},
			cancelBlock: { (picker) in
				// cancelled
			},
			origin: sender)
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

	@IBAction func segueFromTutorial(segue: UIStoryboardSegue) {
	}

	func observeApplicationBecameActive() {
        let defaults = NSUserDefaults.standardUserDefaults()
        
		if regions.first! == nil {
			if INTULocationManager.locationServicesState() == .Available {
				resolveLocalPlacemark()
			}
		} else if defaults.boolForKey(PartyUpPreferences.CameraJump) && defaults.boolForKey(PartyUpPreferences.AgreedToTerms) {
			if shouldPerformSegueWithIdentifier("Bake Sample Segue", sender: nil) {
				performSegueWithIdentifier("Bake Sample Segue", sender: nil)
			}
		}
	}
}

extension PartyRootController: CoachMarksControllerDataSource, CoachMarksControllerDelegate {
	func numberOfCoachMarksForCoachMarksController(coachMarksController: CoachMarksController) -> Int {
		return 5
	}

	func coachMarksController(coachMarksController: CoachMarksController, coachMarksForIndex index: Int) -> CoachMark {
		var mark: CoachMark
		switch index {
		case 0...2:
			mark = coachMarksController.coachMarkForView(navigationController?.view.viewWithTag(1000 + index))
		default:
			mark = coachMarksController.coachMarkForView(view.viewWithTag(1000 + index))
		}
		return mark
	}

	func coachMarksController(coachMarksController: CoachMarksController, coachMarkViewsForIndex index: Int, coachMark: CoachMark) -> (bodyView: CoachMarkBodyView, arrowView: CoachMarkArrowView?) {
		let coachViews = coachMarksController.defaultCoachViewsWithArrow(true, withNextText: false, arrowOrientation: coachMark.arrowOrientation)
		switch index {
		case 0:
			coachViews.bodyView.hintLabel.text = "Choose a city whose venues you would like to see in the city hub."
		case 1:
			coachViews.bodyView.hintLabel.text = "Read some documentation and see who contributed to PartyUP."
		case 2:
			coachViews.bodyView.hintLabel.text = "Record and submit a video from the venue you are at."
		case 3:
			coachViews.bodyView.hintLabel.text = "While venues are being loaded, seaching is displayed here."
		case 4:
			coachViews.bodyView.hintLabel.text = "Reminders"
		default:
			coachViews.bodyView.hintLabel.text = "Hmm, not sure what this is."
		}
		return (bodyView: coachViews.bodyView, arrowView: coachViews.arrowView)
	}

	func coachMarksController(coachMarksController: CoachMarksController, coachMarkWillLoadForIndex index: Int) -> Bool {
		return true
	}

	func coachMarksController(coachMarksController: CoachMarksController, constraintsForSkipView skipView: UIView, inParentView parentView: UIView) -> [NSLayoutConstraint]? {

		var constraints: [NSLayoutConstraint] = []

		constraints.append(NSLayoutConstraint(item: skipView, attribute: .CenterXWithinMargins, relatedBy: .Equal, toItem: parentView, attribute: .CenterX, multiplier: 1.0, constant: 0))
		constraints.append(NSLayoutConstraint(item: skipView, attribute: .Bottom, relatedBy: .Equal, toItem: parentView, attribute: .BottomMargin, multiplier: 1.0, constant: 0.0))

		return constraints
	}
}
