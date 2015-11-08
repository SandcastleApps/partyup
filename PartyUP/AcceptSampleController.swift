//
//  AcceptSampleController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-10-02.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit
import CoreLocation
import SwiftLocation
import Player
import ActionSheetPicker_3_0

class AcceptSampleController: UIViewController, PlayerDelegate, UITextFieldDelegate {

	var videoUrl: NSURL?
	var venues: [Venue]?

	private var locals = [Venue](){
		didSet {
			venue.setTitle(locals.first?.name ?? "No Venues Available", forState: .Normal)
		}
	}

	private var selectedLocal = 0

	@IBOutlet weak var comment: UITextField! {
		didSet {
			comment.delegate = self
		}
	}

	@IBOutlet weak var venue: UIButton!

	private let player = Player()

	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.titleView = PartyUpConstants.TitleLogo()

		do {
			try SwiftLocation.shared.currentLocation(.Block, timeout: 20,
				onSuccess: { (location) in
					if let location = location, venues = self.venues {
						let radius = NSUserDefaults.standardUserDefaults().doubleForKey(PartyUpPreferences.SampleRadius)
						let locs = venues.filter { venue in return location.distanceFromLocation(venue.location) <= radius + location.horizontalAccuracy }
						dispatch_async(dispatch_get_main_queue()) { self.locals = locs }
					}
				},
				onFail: { (error) in
					//handle
			})
		} catch {
			//handle error
		}

		player.delegate = self
		player.view.translatesAutoresizingMaskIntoConstraints = false

		addChildViewController(player)
		view.insertSubview(player.view, atIndex: 0)
		player.didMoveToParentViewController(self)

		view.addConstraint(NSLayoutConstraint(
			item: player.view,
			attribute: .CenterX,
			relatedBy: .Equal,
			toItem: view,
			attribute: .CenterX,
			multiplier: 1.0,
			constant: 0))

		view.addConstraint(NSLayoutConstraint(
			item: player.view,
			attribute: .Width,
			relatedBy: .Equal,
			toItem: view,
			attribute: .Width,
			multiplier: 1.0,
			constant: 0))

		view.addConstraint(NSLayoutConstraint(
			item: player.view,
			attribute: .Height,
			relatedBy: .Equal,
			toItem: player.view,
			attribute: .Width,
			multiplier: 1.0,
			constant: 0))

		view.addConstraint(NSLayoutConstraint(
			item: player.view,
			attribute: .Bottom,
			relatedBy: .Equal,
			toItem: view,
			attribute: .Bottom,
			multiplier: 1.0,
			constant: 0))

		if let url = videoUrl {
			player.setUrl(url)
			player.playbackLoops = true
			player.playFromBeginning()
		}

	}

	// MARK: - Venue Picker

	@IBAction func selectVenue(sender: UIButton) {
		ActionSheetStringPicker.showPickerWithTitle("Venue", rows: locals.map { $0.name }, initialSelection: 0,
			doneBlock: { (picker, row, value) in
				self.selectedLocal = row
				sender.titleLabel?.text = value as! String
			},
			cancelBlock: { (picker) in
				// cancelled
			},
			origin: view)
	}

	// MARK: - Keyboard

	func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
		return true
	}

	func textFieldShouldReturn(textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}

    // MARK: - Navigation

	@IBAction func rejectSample(sender: UIBarButtonItem) {
		do {
			if let url = videoUrl {
				try NSFileManager.defaultManager().removeItemAtURL(url)
			}
		} catch {
			NSLog("Failed to delete rejected video: \(videoUrl) with error: \(error)")
		}

		host?.rejectedSample()
	}

	@IBAction func acceptSample(sender: UIBarButtonItem) {
		do {
			if let url = videoUrl {
				let sample = Sample(comment: comment.text)
				try NSFileManager.defaultManager().moveItemAtURL(url, toURL: NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(sample.media.path!))
				SampleManager.defaultManager().submit(sample, event: locals[selectedLocal].unique)
			}

		} catch {
			NSLog("Failed to move accepted video: \(videoUrl) with error: \(error)")
		}

		host?.acceptedSample()
	}

	// MARK: - Player

	func playerPlaybackWillStartFromBeginning(player: Player) {
	}

	func playerPlaybackDidEnd(player: Player) {
	}

	func playerReady(player: Player) {
	}

	func playerPlaybackStateDidChange(player: Player) {
	}

	func playerBufferingStateDidChange(player: Player) {
	}

	// MARK: - Hosted

	var host: BakeRootController?

	override func didMoveToParentViewController(parent: UIViewController?) {
		host = parent as? BakeRootController
		if host != nil {

		} else {
			comment.text = ""
		}
	}
}
