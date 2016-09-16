//
//  AcceptSampleController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-10-02.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit
import VIMVideoPlayer
import ActionSheetPicker_3_0
import SCLAlertView
import Flurry_iOS_SDK

class AcceptSampleController: UIViewController, VIMVideoPlayerViewDelegate, UITextViewDelegate {

    var videoUrl: NSURL? {
        didSet {
            prepareOverlayFor(videoUrl)
        }
    }
    
	var transitionStartY: CGFloat = 0.0

	var venues = [Venue]() {
		didSet {
			venueButtonState()
		}
	}

	private var selectedLocal = 0
	private var selectedAlias = 0

	@IBOutlet weak var comment: UITextView! {
		didSet {
			comment.delegate = self
			setCommentPlaceholder()
		}
	}

	@IBOutlet weak var naviBar: UINavigationBar!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var encodingProgress: UIActivityIndicatorView! 
	@IBOutlet weak var review: UIView!
	@IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var sendView: UIView!

	private let playView = VIMVideoPlayerView()
	private var waiting: SCLAlertViewResponder?
    private var exporter: AVAssetExportSession?

	override func viewDidLoad() {
		super.viewDidLoad()

		naviBar.topItem?.titleView = PartyUpConstants.TitleLogo()
        
        if let exporter = exporter where exporter.status == .Exporting {
            encodingProgress.startAnimating()
            shareButton.hidden = true
            shareButton.enabled = false
        }

		playView.translatesAutoresizingMaskIntoConstraints = false
		playView.layer.cornerRadius = 10
		playView.layer.masksToBounds = true
		playView.player.looping = true

		review.insertSubview(playView, atIndex: 0)

		review.addConstraint(NSLayoutConstraint(
			item: playView,
			attribute: .CenterX,
			relatedBy: .Equal,
			toItem: review,
			attribute: .CenterX,
			multiplier: 1.0,
			constant: 0))

		review.addConstraint(NSLayoutConstraint(
			item: playView,
			attribute: .Width,
			relatedBy: .Equal,
			toItem: review,
			attribute: .Width,
			multiplier: 1.0,
			constant: 0))

		review.addConstraint(NSLayoutConstraint(
			item: playView,
			attribute: .Height,
			relatedBy: .Equal,
			toItem: playView,
			attribute: .Width,
			multiplier: 1.0,
			constant: 0))

		review.addConstraint(NSLayoutConstraint(
			item: playView,
			attribute: .Bottom,
			relatedBy: .Equal,
			toItem: review,
			attribute: .Bottom,
			multiplier: 1.0,
			constant: 0))

		let notify = NSNotificationCenter.defaultCenter()
		notify.addObserver(self, selector: #selector(AcceptSampleController.observeApplicationBecameActive), name: UIApplicationDidBecomeActiveNotification, object: nil)
		notify.addObserver(self, selector: #selector(AcceptSampleController.observeApplicationEnterBackground), name: UIApplicationDidEnterBackgroundNotification, object: nil)
	}

	deinit {
        prepareOverlayFor(nil)
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}
    
    private func prepareOverlayFor(url: NSURL?) {
        exporter?.cancelExport()
        exporter = nil
        if let input = url {
            shareButton?.hidden = true
            encodingProgress?.startAnimating()
            let output = input.URLByDeletingLastPathComponent!.URLByAppendingPathComponent("PartyUp.mp4")
            let _ = try? NSFileManager.defaultManager().removeItemAtURL(output!)
            exporter = applyToVideo(fromInput: input, toOutput: output!, effectApplicator: AcceptSampleController.generateOverlayOnComposition(self), exportCompletionHander: { status in
                self.encodingProgress?.stopAnimating()
                self.shareButton?.hidden = false
                self.shareButton?.enabled = status == .Completed
            } )
        }
        
        if exporter == nil {
            encodingProgress?.stopAnimating()
            shareButton?.hidden = false
            shareButton?.enabled = false
        }
    }

	// MARK: - View Lifecycle

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		review.hidden = true
		comment.hidden = true
		alias.hidden = true
		venue.hidden = true
		sendView.hidden = true
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		let offset = transitionStartY - review.frame.origin.y

		review.transform = CGAffineTransformMakeTranslation(0, offset)
		comment.transform = CGAffineTransformMakeTranslation(0, offset)
		venue.transform = CGAffineTransformMakeTranslation(0, offset)
		alias.transform = CGAffineTransformMakeTranslation(0, offset)
		sendView.transform = CGAffineTransformMakeTranslation(0, sendView.bounds.height)
		sendButton.transform = CGAffineTransformMakeTranslation(-sendButton.bounds.width, 0)

		review.hidden = false
		comment.hidden = false
		venue.hidden = false
		alias.hidden = false
		sendView.hidden = false

		UIView.animateWithDuration(0.5,
			delay: 0,
			usingSpringWithDamping: 0.85,
			initialSpringVelocity: 10,
			options: [],
			animations: {
				self.review.transform = CGAffineTransformIdentity
				self.sendView.transform = CGAffineTransformIdentity
			},
			completion: nil)

		UIView.animateWithDuration(0.5,
			delay: 0.2,
			usingSpringWithDamping: 0.75,
			initialSpringVelocity: 10,
			options: [],
			animations: {
				self.sendButton.transform = CGAffineTransformIdentity
			},
			completion: nil)

		UIView.animateWithDuration(0.5,
			delay: 0.1,
			usingSpringWithDamping: 0.85,
			initialSpringVelocity: 10,
			options: [],
			animations: {
				self.alias.transform = CGAffineTransformIdentity
			},
			completion: nil)

		UIView.animateWithDuration(0.5,
			delay: 0.2,
			usingSpringWithDamping: 0.85,
			initialSpringVelocity: 10,
			options: [],
			animations: {
				self.venue.transform = CGAffineTransformIdentity
			},
			completion: nil)

		UIView.animateWithDuration(0.5,
			delay: 0.3,
			usingSpringWithDamping: 0.85,
			initialSpringVelocity: 10,
			options: [],
			animations: {
				self.comment.transform = CGAffineTransformIdentity
			},
			completion: { done in if done { self.tutorial.start(self) } })
	}
	//MARK: - Alias Picker

	private let aliases = [NSLocalizedString("Post Anonymously", comment: "anonymous user moniker")] + AuthenticationManager.shared.user.aliases.values

	@IBOutlet weak var alias: UIButton! {
		didSet {
			aliasButtonState()
		}
	}

	func aliasButtonState() {
		var label = "Anonymous"

		if selectedAlias < aliases.count {
			label = aliases[selectedAlias]
		}

		alias?.setTitle(label, forState: .Disabled)

		if aliases.count > 1 {
			label += " ▼"
			alias?.setTitle(label, forState: .Normal)
		} else {
			alias?.enabled = false
		}
	}
	
	@IBAction func selectAlias(sender: UIButton) {
		view.endEditing(false)

		let sheet = ActionSheetStringPicker(title: NSLocalizedString("Alias", comment: "Title of the alias picker"),
			rows: aliases,
			initialSelection: 0,
			doneBlock: { (_, row, _) in
				self.selectedAlias = row
				self.aliasButtonState()
			},
			cancelBlock: { _ in
				// cancelled
			},
			origin: sender)
		sheet.toolbarButtonsColor = UIColor(r: 247, g: 126, b: 86, alpha: 255)
		sheet.showActionSheetPicker()
	}

	// MARK: - Venue Picker

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

	@IBAction func selectVenue(sender: UIButton) {
		view.endEditing(false)
		
		let sheet = ActionSheetStringPicker(title: NSLocalizedString("Venue", comment: "Title of the venue picker"),
			rows: venues.map { $0.name },
			initialSelection: 0,
			doneBlock: { (_, row, _) in
				self.selectedLocal = row
				self.venueButtonState()
			},
			cancelBlock: { _ in
				// cancelled
			},
			origin: sender)
		sheet.toolbarButtonsColor = UIColor(r: 247, g: 126, b: 86, alpha: 255)
		sheet.showActionSheetPicker()
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

    @IBAction func shareSample(sender: UIButton) {
        if let url = exporter?.outputURL {
            var statement = "Shared from PartyUP!"
            if let addendum = commentCleanUp() {
                statement += "\n\n" + addendum
            }
            let share = UIActivityViewController(activityItems: [statement, url], applicationActivities: nil)
            share.popoverPresentationController?.sourceView = sender
			share.popoverPresentationController?.sourceRect = sender.bounds
            self.presentViewController(share, animated: true, completion: nil)
            
            Flurry.logEvent("Sample_Shared_Externally")
        }
    }
    
	@IBAction func rejectSample(sender: UIBarButtonItem) {
		view.endEditing(false)

	#if !((arch(i386) || arch(x86_64)) && os(iOS))
		do {
			if let url = videoUrl {
				try NSFileManager.defaultManager().removeItemAtURL(url)
			}
		} catch {
			NSLog("Failed to delete rejected video: \(videoUrl) with error: \(error)")
		}
	#endif

		Flurry.logEvent("Sample_Rejected")

		host?.rejectedSample()
	}
    
    func commentCleanUp() -> String? {
        var statement: String? = comment.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        statement = statement?.isEmpty ?? true || comment.textColor != UIColor.blackColor() ? nil : statement
        
        return statement
    }

	@IBAction func acceptSample(sender: UIButton) {
		view.endEditing(false)

		do {
			if let url = videoUrl {
				waiting = alertWaitWithTitle(NSLocalizedString("Uploading Party Post", comment: "Hud title while uploading a post"), closeButton: nil)
				let statement = commentCleanUp()
				let place = venues[selectedLocal]
				let alias: String? = selectedAlias > 0 ? aliases[selectedAlias] : nil
				let sample = Sample(event: place, alias: alias, comment: statement)
				Flurry.logEvent("Sample_Accepted", withParameters: ["timestamp" : sample.time, "comment" : sample.comment?.characters.count ?? 0, "venue" : place.unique, "alias" : alias ?? "Anon"], timed: true)
				#if (arch(i386) || arch(x86_64)) && os(iOS)
					try NSFileManager.defaultManager().copyItemAtURL(url, toURL: NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(sample.media.path!)!)
				#else
					try NSFileManager.defaultManager().moveItemAtURL(url, toURL: NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(sample.media.path!)!)
				#endif
                let submission = Submission(sample: sample)
				submission.submitWithCompletionHander(completionHandlerForSubmission)
			} else {
				alertFailureWithTitle(NSLocalizedString("Upload Failed", comment: "Hud title when failed due to no video"),
				                      andDetail: NSLocalizedString("No video available.", comment: "Hud detail indicating no video available")) { self.host?.acceptedSample() }
			}

		} catch {
			self.waiting?.close()
			Flurry.logError("Submission_Failed", message: "\(error)", error: nil)
			alertFailureWithTitle(NSLocalizedString("Video Missing", comment: "Hud title when failed due to no video"),
				andDetail: NSLocalizedString("Couldn't queue post for upload.", comment: "Hud title when failed due to no video")) { self.host?.acceptedSample() }
		}
	}

	private func completionHandlerForSubmission(submission: Submission) {
		if let error = submission.error {
			Flurry.logError("Submission_Failed", message: "\(error)", error: nil)
			let alert = SCLAlertView(appearance: SCLAlertView.SCLAppearance(showCloseButton: false))
			alert.addButton(NSLocalizedString("Discard", comment: "Submission discard alert button")) {
				Flurry.endTimedEvent("Sample_Accepted", withParameters: ["status" : false])
				self.waiting?.close()
				self.host?.rejectedSample()
			}
			alert.addButton(NSLocalizedString("Retry", comment: "Submission retry alert button")) {
				submission.submitWithCompletionHander(self.completionHandlerForSubmission)
			}
			alert.showWarning(NSLocalizedString("Submission Failed", comment: "Alert title after unsuccessfully uploaded sample"),
			                  subTitle: NSLocalizedString("You may discard the post or try submitting it again.", comment: "Alert detail after unsuccessfully uploaded sample"),
			                  colorStyle: 0xf77e56)
		} else {
			self.waiting?.close()
			Flurry.endTimedEvent("Sample_Accepted", withParameters: ["status" : true])
			alertSuccessWithTitle(NSLocalizedString("Submission Done", comment: "Hud title after successfully uploaded sample"),
				andDetail: NSLocalizedString("Party On!", comment: "Hud detail after successfully uploaded sample")) { self.host?.acceptedSample() }
			UIView.animateWithDuration(2.0,
				delay: 0.2,
				usingSpringWithDamping: 1.0,
				initialSpringVelocity: 10,
				options: [],
				animations: {
					self.sendButton.transform = CGAffineTransformMakeTranslation(self.sendView.bounds.width, 0)
				},
				completion: nil)
			self.venues[self.selectedLocal].fetchSamples()
		}
	}

	// MARK: - Hosted

	private weak var host: BakeRootController?
	
	override func didMoveToParentViewController(parent: UIViewController?) {
		super.didMoveToParentViewController(parent)

		host = parent as? BakeRootController
		if host == nil {
			selectedLocal = 0
			setCommentPlaceholder()
			playView.player.reset()
        } else {
			if let url = videoUrl {
				playView.player.setURL(url)
				playView.player.play()
			}
		}
	}

	// MARK: - Application Lifecycle

	func observeApplicationBecameActive() {
		playView.player.play()
	}

	func observeApplicationEnterBackground() {
		playView.player.pause()
	}
    
    // MARK: - Overlay
    
    func generateOverlayOnComposition(composition: AVMutableVideoComposition) {
        if let logo = UIImage(named: "Watermark") {
            let size = composition.renderSize
            let over = CALayer()
            over.contents = logo.CGImage
            over.frame = CGRectMake(size.width - logo.size.width - 10, logo.size.height - 10, logo.size.width, logo.size.height)
			over.masksToBounds = true
            over.opacity = 0.65
            
            let parent = CALayer()
            parent.frame = CGRectMake(0, 0, size.width, size.height)
            let video = CALayer()
            video.frame = CGRectMake(0, 0, size.width, size.height)
            parent.addSublayer(video)
            parent.addSublayer(over)
            
            composition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: video, inLayer: parent)
        }
    }

	// MARK: - Tutorial

	private enum CoachIdentifier: Int {
		case Greeting = -2100, Comment = 2101, Venue, Submit, Alias
	}

	private static let availableCoachMarks = [
        TutorialMark(identifier: CoachIdentifier.Venue.rawValue, hint: NSLocalizedString("Tap to select where\nyou are partying.", comment: "Accept video venue selection coachmark")),
        TutorialMark(identifier: CoachIdentifier.Alias.rawValue, hint: NSLocalizedString("Tap to select one of\nyour social aliases.", comment: "Accept video alias selection coachmark"))]

	private let tutorial = TutorialOverlayManager(marks: AcceptSampleController.availableCoachMarks)
}

extension AcceptSampleController: UIBarPositioningDelegate {
	func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
		return .TopAttached
	}
}
