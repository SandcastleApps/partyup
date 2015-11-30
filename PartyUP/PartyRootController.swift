//
//  PartyRootController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-11-07.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit
import ActionSheetPicker_3_0
import CoreLocation

class PartyRootController: UIViewController {

	@IBOutlet weak var cameraButton: UIBarButtonItem!

	private var partyPicker: PartyPickerController!
	private var regions: [PartyPickerController.PartyRegion] = [(NSLocalizedString("Nearby Parties", comment: "Name of the current location region"), nil)]
	private var selectedRegion = 0

    override func viewDidLoad() {
        super.viewDidLoad()

		regions.append((name: "Halifax Parties", location: CLLocation(latitude: 44.651070,longitude: -63.582687)))
		regions.append((name: "Sydney Parties", location: CLLocation(latitude: 46.13631,longitude: -60.19551)))

		NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("observeApplicationBecameActive"), name: UIApplicationDidBecomeActiveNotification, object: nil)
    }

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "Party Embed Segue" {
			partyPicker = segue.destinationViewController as! PartyPickerController
			partyPicker.lockedLocation = regions[selectedRegion]
		}
		if segue.identifier == "Bake Sample Segue" {
			let bakerVC = segue.destinationViewController as! BakeRootController
			bakerVC.venues = partyPicker.venues ?? [Venue]()
		}
	}


	@IBAction func loadPreferences(sender: UIButton) {
		NSLog("load prefs")
	}

	@IBAction func chooseLocation(sender: UIBarButtonItem) {
		ActionSheetStringPicker.showPickerWithTitle(NSLocalizedString("Region", comment: "Title of the region picker"),
			rows: regions.map { $0.name },
			initialSelection: selectedRegion,
			doneBlock: { (picker, row, value) in
				self.selectedRegion = row
				self.partyPicker.lockedLocation = self.regions[row]
				self.cameraButton.enabled = self.regions[row].location == nil
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
			performSegueWithIdentifier("Bake Sample Segue", sender: nil)
		}
	}
}
