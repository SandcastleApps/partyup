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

class PartyRootController: UIViewController {

	@IBOutlet weak var cameraImage: UIImageView!
	@IBOutlet weak var busyIndicator: UIActivityIndicatorView!
	@IBOutlet weak var busyLabel: UILabel!
	@IBOutlet weak var ackButton: UIButton!

	private let progressHud = JGProgressHUD(style: .Light)

	private var partyPicker: PartyPickerController!
	private var regions: [PartyPlace!] = [nil]
	private var selectedRegion = 0

    override func viewDidLoad() {
        super.viewDidLoad()

		UIView.animateWithDuration(0.5, delay: 0, options: [.Autoreverse, .Repeat, .AllowUserInteraction], animations: { self.ackButton.alpha = 0.85 }, completion: nil)

		resolvePopularPlacemarks()
		resolveLocalPlacemark()

		let nc = NSNotificationCenter.defaultCenter()
		nc.addObserver(self, selector: Selector("observeApplicationBecameActive"), name: UIApplicationDidBecomeActiveNotification, object: nil)
		nc.addObserver(self, selector: Selector("refreshSelectedRegion"), name: PartyPickerController.VenueRefreshRequest, object: nil)
    }

	func refreshSelectedRegion() {
		fetchPlaceVenues(regions[selectedRegion])
	}

	func resolvePopularPlacemarks() {
		if let cities = NSUserDefaults.standardUserDefaults().arrayForKey(PartyUpPreferences.StickyTowns) as? [String] {
			for city in cities {
				LMGeocoder().geocodeAddressString(city, service: .GoogleService) { (places, error) in
					if let place = places?.first as? LMAddress where error == nil {
						dispatch_async(dispatch_get_main_queue(), {
							self.regions.append(PartyPlace(place: place))
						})
					} else {
						NSLog("Place Error: \(error)")
					}
				}
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
								dispatch_async(dispatch_get_main_queue(), {
									if let index = self.regions.indexOf({ $0?.place.locality == place.locality }) {
										self.regions[0] = self.regions[index]
									} else {
										self.regions[0] = PartyPlace(place: place)
									}
									self.fetchPlaceVenues(self.regions.first!)

									Flurry.setLatitude(location!.coordinate.latitude, longitude: location!.coordinate.longitude, horizontalAccuracy: Float(location!.horizontalAccuracy), verticalAccuracy: Float(location!.verticalAccuracy))
								})
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

					Flurry.logError("City_Determination_Failed", message: "Reason \(status)", error: nil)
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
                place.fetch(radius, categories: categories) { (success, more) in
                    dispatch_async(dispatch_get_main_queue()) {
                        if success {
                            self.partyPicker.parties = self.regions[self.selectedRegion]
                        } else {
                            presentResultHud(self.progressHud,
                                inView: self.view,
                                withTitle: NSLocalizedString("Venue Query Failed", comment: "Hud title failed to fetch venues from foursquare"),
                                andDetail: NSLocalizedString("The venue query failed.", comment: "Hud detail failed to fetch venues from foursquare"),
                                indicatingSuccess: false)
                        }
                        
                        if !more {
                            place.venues?.forEach { $0.fetchSamples() }
                            
                            self.busyIndicator.stopAnimating()
                            self.busyLabel.text = ""
                        }
                    }
                }
            }
        } else {
            self.partyPicker.parties = self.regions[self.selectedRegion]
        }
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		let defaults = NSUserDefaults.standardUserDefaults()
		if defaults.boolForKey(PartyUpPreferences.PlayTutorial) {
			defaults.setBool(false, forKey: PartyUpPreferences.PlayTutorial)
			let story = UIStoryboard.init(name: "Tutorial", bundle: nil)
			if let tutorial = story.instantiateInitialViewController() {
				presentViewController(tutorial, animated: true, completion: nil)
			}
		}

		UIView.animateWithDuration(0.5,
			delay: 3,
			options: [.AllowUserInteraction, .CurveEaseInOut],
			animations: {
				self.cameraImage.transform = CGAffineTransformMakeScale(0.5,0.5) } ,
			completion: { (done) in
				UIView.animateWithDuration(0.5,
					delay: 0,
					options: [.AllowUserInteraction, .CurveEaseInOut],
					animations: { self.cameraImage.transform = CGAffineTransformMakeScale(1.5,1.5) },
					completion: { (done) in
						UIView.animateWithDuration(0.5,
							delay: 0,
							usingSpringWithDamping: 0.10,
							initialSpringVelocity: 1,
							options: .AllowUserInteraction,
							animations: { self.cameraImage.transform = CGAffineTransformIdentity },
							completion: nil)
				})
		})
	}

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

    // MARK: - Navigation

	override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
		if identifier == "Bake Sample Segue" {
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
			bakerVC.venues = regions.first??.venues ?? [Venue]()
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
			origin: view)
	}

	@IBAction func sequeFromBaking(segue: UIStoryboardSegue) {
	}

	@IBAction func segueFromTasting(segue: UIStoryboardSegue) {
		Flurry.logEvent("Returned_From_Tasting")
	}

	@IBAction func segueFromAcknowledgements(segue: UIStoryboardSegue) {

	}

	@IBAction func segueFromTutorial(segue: UIStoryboardSegue) {

	}

	func observeApplicationBecameActive() {
		if regions.first! == nil {
			if INTULocationManager.locationServicesState() == .Available {
				resolveLocalPlacemark()
			}
		} else if NSUserDefaults.standardUserDefaults().boolForKey(PartyUpPreferences.CameraJump) {
			if shouldPerformSegueWithIdentifier("Bake Sample Segue", sender: nil) {
				performSegueWithIdentifier("Bake Sample Segue", sender: nil)
			}
		}
	}
}
