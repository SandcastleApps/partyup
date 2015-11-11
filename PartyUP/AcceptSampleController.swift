//
//  AcceptSampleController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-10-02.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit
import Player
import ActionSheetPicker_3_0

class AcceptSampleController: UIViewController, PlayerDelegate, UITextFieldDelegate {

	var videoUrl: NSURL?

	var venues = [Venue]() {
		didSet {
			venueButtonState()
		}
	}

	private var selectedLocal = 0

	@IBOutlet weak var comment: UITextField! {
		didSet {
			comment.delegate = self
		}
	}

	@IBOutlet weak var venue: UIButton! {
		didSet {
			venueButtonState()
		}
	}

	private func venueButtonState() {
		var label = "No Venues Available"

		if selectedLocal < venues.count {
			label = venues[selectedLocal].name
		}

		venue?.setTitle(label, forState: .Disabled)

		if venues.count > 1 {
			label += " ▼"
			venue?.setTitle(label, forState: .Normal)
		} else {
			venue?.enabled = false
		}
	}

	@IBOutlet weak var naviBar: UINavigationBar!
	@IBOutlet weak var review: UIView!
	

	private let player = Player()

	override func viewDidLoad() {
		super.viewDidLoad()

		naviBar.topItem?.titleView = PartyUpConstants.TitleLogo()

//		player.delegate = self
		player.view.translatesAutoresizingMaskIntoConstraints = false
		player.view.layer.cornerRadius = 10
		player.view.layer.masksToBounds = true

		addChildViewController(player)
		review.insertSubview(player.view, atIndex: 0)
		player.didMoveToParentViewController(self)

		review.addConstraint(NSLayoutConstraint(
			item: player.view,
			attribute: .CenterX,
			relatedBy: .Equal,
			toItem: review,
			attribute: .CenterX,
			multiplier: 1.0,
			constant: 0))

		review.addConstraint(NSLayoutConstraint(
			item: player.view,
			attribute: .Width,
			relatedBy: .Equal,
			toItem: review,
			attribute: .Width,
			multiplier: 1.0,
			constant: 0))

		review.addConstraint(NSLayoutConstraint(
			item: player.view,
			attribute: .Height,
			relatedBy: .Equal,
			toItem: player.view,
			attribute: .Width,
			multiplier: 1.0,
			constant: 0))

		review.addConstraint(NSLayoutConstraint(
			item: player.view,
			attribute: .Bottom,
			relatedBy: .Equal,
			toItem: review,
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
		view.endEditing(false)
		
		ActionSheetStringPicker.showPickerWithTitle("Venue", rows: venues.map { $0.name }, initialSelection: 0,
			doneBlock: { (picker, row, value) in
				self.selectedLocal = row
				self.venueButtonState()
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
		view.endEditing(false)
		return true
	}

	override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
		view.endEditing(false)
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
				SampleManager.defaultManager().submit(sample, event: venues[selectedLocal].unique)
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

	private weak var host: BakeRootController?

	override func didMoveToParentViewController(parent: UIViewController?) {
		host = parent as? BakeRootController
		if host != nil {

		} else {
			comment.text = ""
		}
	}
}
