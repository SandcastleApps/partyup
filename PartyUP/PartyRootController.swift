//
//  PartyRootController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-11-07.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit
import ActionSheetPicker_3_0
import SwiftLocation
import CoreLocation
import JGProgressHUD
import Flurry_iOS_SDK

class PartyRootController: UIViewController {

	@IBOutlet weak var cameraImage: UIImageView!
	@IBOutlet weak var busyIndicator: UIActivityIndicatorView!
	@IBOutlet weak var busyLabel: UILabel!

	private let progressHud = JGProgressHUD(style: .Light)

	private var partyPicker: PartyPickerController!
	private var regions: [PartyPlace] = []
	private var selectedRegion = 0

    override func viewDidLoad() {
        super.viewDidLoad()

		resolvePopularPlacemarks()
		resolveLocalPlacemark()

		NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("observeApplicationBecameActive"), name: UIApplicationDidBecomeActiveNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("resolveLocalPlacemark"), name: PartyPickerController.VenueRefreshRequest, object: nil)
    }

	func resolvePopularPlacemarks() {
		let cities = [ "Halifax, NS, Canada", "Sydney, NS, Canada"]

		for city in cities {
			SwiftLocation.shared.reverseAddress(.GoogleMaps, address: city, region: nil,
				onSuccess: { (place) in
					dispatch_async(dispatch_get_main_queue(), {
						self.regions.append(PartyPlace(place: place!))
					})
				},
				onFail: { (error) in
					NSLog("Place Error: \(error)")
			})
		}
	}


	func resolveLocalPlacemark() {
		busyIndicator.startAnimating()
		busyLabel.text = "locating"

		do {
			try SwiftLocation.shared.currentLocation(.City, timeout: 60,
				onSuccess: { (location) in
					SwiftLocation.shared.reverseCoordinates(.Apple, coordinates: location?.coordinate,
						onSuccess: { (place) in
							dispatch_async(dispatch_get_main_queue(), {
								if let local = self.regions.first where local.sticky == false {
									self.regions.removeFirst()
								}

								if let index = self.regions.indexOf({ $0.place.locality == place?.locality }) {
									if index > 0 {
										swap(&self.regions[0], &self.regions[index])
									}
								} else {
									self.regions.insert(PartyPlace(place: place!, sticky: false), atIndex: 0)
								}
								self.fetchPlaceVenues(self.regions.first!)

								Flurry.setLatitude(location!.coordinate.latitude, longitude: location!.coordinate.longitude, horizontalAccuracy: Float(location!.horizontalAccuracy), verticalAccuracy: Float(location!.verticalAccuracy))
							})
						},
						onFail: { (error) in
							self.busyIndicator.stopAnimating()
							self.busyLabel.text = ""

							Flurry.logError("City_Determination_Failed", message: error!.localizedDescription, error: error)
							presentResultHud(self.progressHud,
								inView: self.view,
								withTitle: NSLocalizedString("Undetermined Location", comment: "Hud title location onFail message"),
								andDetail: NSLocalizedString("Location services failure.", comment: "Hud detail location onFail message"),
								indicatingSuccess: false)
					})
				},
				onFail: { (error) in
					self.busyIndicator.stopAnimating()
					self.busyLabel.text = ""

					Flurry.logError("City_Determination_Failed", message: error!.localizedDescription, error: error)
					presentResultHud(self.progressHud,
						inView: self.view,
						withTitle: NSLocalizedString("Undetermined Location", comment: "Hud title location onFail message"),
						andDetail: NSLocalizedString("Location services failure.", comment: "Hud detail location onFail message"),
						indicatingSuccess: false)
			})
		} catch {
			busyIndicator.stopAnimating()
			busyLabel.text = ""

			presentResultHud(progressHud,
				inView: view,
				withTitle: NSLocalizedString("Undeterined Location", comment: "Hud title location caught error"),
				andDetail: NSLocalizedString("Location services failure.", comment: "Hud detail location caught error"),
				indicatingSuccess: false)
		}
	}

	func fetchPlaceVenues(place: PartyPlace) {
		busyIndicator.startAnimating()
		busyLabel.text = "fetching"

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
						self.busyIndicator.stopAnimating()
						self.busyLabel.text = ""
					}
				}
			}
		}
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

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
			if presentedViewController is BakeRootController {
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
			bakerVC.venues = regions.first?.venues ?? [Venue]()
		}
	}


	@IBAction func loadPreferences(sender: UIButton) {
		NSLog("load prefs")
	}

	@IBAction func chooseLocation(sender: UIBarButtonItem) {
		ActionSheetStringPicker.showPickerWithTitle(NSLocalizedString("Region", comment: "Title of the region picker"),
			rows: regions.map { $0.place.locality! },
			initialSelection: selectedRegion,
			doneBlock: { (picker, row, value) in
				self.fetchPlaceVenues(self.regions[row])
				self.selectedRegion = row
			},
			cancelBlock: { (picker) in
				// cancelled
			},
			origin: view)
	}

	@IBAction func sequeFromBaking(segue: UIStoryboardSegue) {

	}

	@IBAction func segueFromTasting(segue: UIStoryboardSegue) {

	}

	func observeApplicationBecameActive() {
		if NSUserDefaults.standardUserDefaults().boolForKey(PartyUpPreferences.CameraJump) {
			if shouldPerformSegueWithIdentifier("Bake Sample Segue", sender: nil) {
				performSegueWithIdentifier("Bake Sample Segue", sender: nil)
			}
		}
	}
}
