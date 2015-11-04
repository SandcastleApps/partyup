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

class AcceptSampleController: UIViewController, PlayerDelegate, UIPickerViewDataSource, UIPickerViewDelegate {

	var videoUrl: NSURL!
	var venues: [Venue]?
	var locals = [Venue]() {
		didSet {
			venuePicker.reloadComponent(0)
		}
	}

	@IBOutlet weak var commentField: UITextField!
	@IBOutlet weak var venuePicker: UIPickerView!
	@IBOutlet weak var videoReview: UIView!

	let player = Player()
	
	override func prefersStatusBarHidden() -> Bool {
		return true
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		venuePicker.dataSource = self
		venuePicker.delegate = self

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
			attribute: .Top,
			relatedBy: .Equal,
			toItem: view,
			attribute: .Top,
			multiplier: 1.0,
			constant: 0))

		player.setUrl(videoUrl)
		player.playbackLoops = true
		player.playFromBeginning()
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)

		let nc = NSNotificationCenter.defaultCenter()

		nc.addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
		nc.addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
	}

	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)

		let nc = NSNotificationCenter.defaultCenter()

		nc.removeObserver(self, name: UIKeyboardDidShowNotification, object: nil)
		nc.removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
	}

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

	// MARK: - Venue Picker

	func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
		return 1
	}

	func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return locals.count
	}

	func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		return locals[row].name
	}

	// MARK: - Keyboard

	@IBOutlet weak var distantBottom: NSLayoutConstraint!

	func keyboardWillShow(note: NSNotification) {
		if let kbSize = note.userInfo?[UIKeyboardFrameEndUserInfoKey]?.CGRectValue.size,
		kbAnimationDuration = note.userInfo?[UIKeyboardAnimationDurationUserInfoKey]?.doubleValue {
			distantBottom.constant = kbSize.height + 10
			UIView.animateWithDuration(kbAnimationDuration) { self.view.layoutIfNeeded() }
		}
	}

	func keyboardWillHide(note: NSNotification) {

		if let kbAnimationDuration = note.userInfo?[UIKeyboardAnimationDurationUserInfoKey]?.doubleValue {
			distantBottom.constant = 30
			UIView.animateWithDuration(kbAnimationDuration) { self.view.layoutIfNeeded() }
		}
	}

	@IBAction func editingEnded(sender: UITextField) {
		sender.resignFirstResponder()
	}

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "Accept Unwind" {
			do {
				let sample = Sample(comment: commentField.text)
				try NSFileManager.defaultManager().moveItemAtURL(videoUrl, toURL: NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(sample.media.path!))
				SampleManager.defaultManager().submit(sample, event: locals[venuePicker.selectedRowInComponent(0)].unique)

			} catch {
				NSLog("Failed to move accepted video: \(videoUrl) with error: \(error)")
			}

		} else if segue.identifier == "Reject Unwind" {
			do {
				try NSFileManager.defaultManager().removeItemAtURL(videoUrl)
			} catch {
				NSLog("Failed to delete rejected video: \(videoUrl) with error: \(error)")
			}
		}
    }

	// mark: Player

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

}
