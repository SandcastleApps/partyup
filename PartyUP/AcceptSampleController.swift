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
import JGProgressHUD
import Flurry_iOS_SDK

class AcceptSampleController: UIViewController, PlayerDelegate, UITextViewDelegate {

	var videoUrl: NSURL?
	var transitionStartY: CGFloat = 0.0

	var venues = [Venue]() {
		didSet {
			venueButtonState()
		}
	}

	private var selectedLocal = 0

	@IBOutlet weak var comment: UITextView! {
		didSet {
			comment.delegate = self
			setCommentPlaceholder()
		}
	}

	@IBOutlet weak var venue: UIButton! {
		didSet {
			venueButtonState()
		}
	}

	private func venueButtonState() {
		var label = NSLocalizedString("No Venues Available", comment: "Label used in sample acceptance when the user is not near any venues")

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
	@IBOutlet weak var sendButton: UIButton!

	private let player = Player()
	private let progressHud = JGProgressHUD(style: .Light)

	override func viewDidLoad() {
		super.viewDidLoad()

		progressHud.delegate = self

		naviBar.topItem?.titleView = PartyUpConstants.TitleLogo()

		var aniFrames = [UIImage]()

		for x in 1...17 {
			aniFrames.append(UIImage(named: "Send_\(x)")!)
		}

		let sendAnimation = UIImageView(frame: CGRect(x: 0, y: 0, width: 44, height: 36))
		sendAnimation.animationImages = aniFrames
		sendAnimation.animationDuration = 1
		sendAnimation.startAnimating()
		sendButton.addSubview(sendAnimation)
		sendButton.frame = sendAnimation.bounds

		player.view.translatesAutoresizingMaskIntoConstraints = false
		player.view.layer.cornerRadius = 10
		player.view.layer.masksToBounds = true
		player.playbackLoops = true

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

		NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("observeApplicationBecameActive"), name: UIApplicationDidBecomeActiveNotification, object: nil)
	}

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

	// MARK: - View Lifecycle

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		review.hidden = true
		comment.hidden = true
		venue.hidden = true
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		let offset = transitionStartY - review.frame.origin.y

		review.transform = CGAffineTransformMakeTranslation(0, offset)
		comment.transform = CGAffineTransformMakeTranslation(0, offset)
		venue.transform = CGAffineTransformMakeTranslation(0, offset)

		review.hidden = false
		comment.hidden = false
		venue.hidden = false

		UIView.animateWithDuration(0.5,
			delay: 0,
			usingSpringWithDamping: 0.85,
			initialSpringVelocity: 10,
			options: [],
			animations: {
				self.review.transform = CGAffineTransformIdentity
			},
			completion: nil)

		UIView.animateWithDuration(0.5,
			delay: 0.1,
			usingSpringWithDamping: 0.85,
			initialSpringVelocity: 10,
			options: [],
			animations: {
				self.venue.transform = CGAffineTransformIdentity
			},
			completion: nil)

		UIView.animateWithDuration(0.5,
			delay: 0.2,
			usingSpringWithDamping: 0.85,
			initialSpringVelocity: 10,
			options: [],
			animations: {
				self.comment.transform = CGAffineTransformIdentity
			},
			completion: nil)
	}

	// MARK: - Venue Picker

	@IBAction func selectVenue(sender: UIButton) {
		view.endEditing(false)
		
		ActionSheetStringPicker.showPickerWithTitle(NSLocalizedString("Venue", comment: "Title of the venue picker"),
			rows: venues.map { $0.name },
			initialSelection: 0,
			doneBlock: { (picker, row, value) in
				self.selectedLocal = row
				self.venueButtonState()
			},
			cancelBlock: { (picker) in
				// cancelled
			},
			origin: view)
	}

	// MARK: - Text View

	private func setCommentPlaceholder() {
		comment.text = NSLocalizedString("How goes the party?", comment: "Comment placeholder text")
		comment.textColor = UIColor.lightGrayColor()
	}

	func textViewDidBeginEditing(textView: UITextView) {
		if textView.textColor != UIColor.blackColor() {
			textView.text.removeAll()
			textView.textColor = UIColor.blackColor()
		}
	}

	func textViewDidEndEditing(textView: UITextView) {
		if comment.text.isEmpty {
			setCommentPlaceholder()
		}
	}

	func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
		var acceptText = true

		if text == "\n" {
			view.endEditing(false)
			acceptText = false
		}

		return acceptText
	}

	override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
		view.endEditing(false)
	}

    // MARK: - Navigation

	@IBAction func rejectSample(sender: UIBarButtonItem) {
		view.endEditing(false)
		
		do {
			if let url = videoUrl {
				try NSFileManager.defaultManager().removeItemAtURL(url)
			}
		} catch {
			NSLog("Failed to delete rejected video: \(videoUrl) with error: \(error)")
		}

		Flurry.logEvent("Sample_Rejected")

		host?.rejectedSample()
	}

	@IBAction func acceptSample(sender: UIButton) {
		view.endEditing(false)

		do {
			if let url = videoUrl {
				progressHud.textLabel.text = NSLocalizedString("Uploading Party Video", comment: "Hud title while uploading a video")
				progressHud.showInView(view, animated: true)
				var statement: String? = comment.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
				statement = statement?.isEmpty ?? true || comment.textColor != UIColor.blackColor() ? nil : statement
				let place = venues[selectedLocal].unique
                let sample = Sample(event: place, comment: statement)
				Flurry.logEvent("Sample_Accepted", withParameters: ["timestamp" : sample.time, "comment" : sample.comment?.characters.count ?? 0, "venue" : place], timed: true)
				try NSFileManager.defaultManager().moveItemAtURL(url, toURL: NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(sample.media.path!))
				SampleManager.defaultManager().submit(sample, event: place) {(error) in
					if error == nil {
						Flurry.endTimedEvent("Sample_Accepted", withParameters: ["status" : true])
						presentResultHud(self.progressHud,
							inView: self.view,
							withTitle: NSLocalizedString("Submission Done", comment: "Hud title after successfully uploaded sample"),
							andDetail: NSLocalizedString("Party On!", comment: "Hud detail after successfully uploaded sample"),
							indicatingSuccess: true)
						let venue = self.venues[self.selectedLocal]
						venue.vitality? += 1
						NSNotificationCenter.defaultCenter().postNotificationName(Venue.VitalityUpdateNotification, object: venue)
					} else {
						Flurry.endTimedEvent("Sample_Accepted", withParameters: ["status" : false])
						Flurry.logError("Submission_Failed", message: "\(error)", error: nil)
						presentResultHud(self.progressHud,
							inView: self.view,
							withTitle: NSLocalizedString("Submission Failed", comment: "Hud title after unsuccessfully uploaded sample"),
							andDetail: NSLocalizedString("Rats!", comment: "Hud detail after unsuccessfully uploaded sample"),
							indicatingSuccess: false)
					}
				}
			} else {
				presentResultHud(progressHud,
					inView: view,
					withTitle: NSLocalizedString("Upload Failed", comment: "Hud title when failed due to no video"),
					andDetail: NSLocalizedString("No video available.", comment: "Hud detail indicating no video available"),
					indicatingSuccess: false)
			}

		} catch {
			Flurry.logError("Submission_Failed", message: "\(error)", error: nil)
			NSLog("Failed to move accepted video: \(videoUrl) with error: \(error)")
			presentResultHud(progressHud,
				inView: view,
				withTitle: NSLocalizedString("Preparation Failed", comment: "Hud title when failed due to no video"),
				andDetail: NSLocalizedString("Couldn't queue video for upload.", comment: "Hud title when failed due to no video"),
				indicatingSuccess: false)
		}
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
		super.didMoveToParentViewController(parent)

		host = parent as? BakeRootController
		if host == nil {
			selectedLocal = 0
			setCommentPlaceholder()
		} else {
			if let url = videoUrl {
				player.setUrl(url)
				player.playFromBeginning()
			}
		}
	}

	// MARK: - Application Lifecycle

	func observeApplicationBecameActive() {
		if player.playbackState == .Paused && isViewLoaded() && view.window != nil {
			player.playFromCurrentTime()
		}
	}
}

extension AcceptSampleController: UIBarPositioningDelegate {
	func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
		return .TopAttached
	}
}

extension AcceptSampleController: JGProgressHUDDelegate {
	func progressHUD(progressHUD: JGProgressHUD!, didDismissFromView view: UIView!) {
		self.host?.acceptedSample()
	}
}
