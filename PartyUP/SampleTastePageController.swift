//
//  SampleTastePageController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-24.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit
import VIMVideoPlayer
import Social
import DACircularProgress
import Flurry_iOS_SDK

class SampleTastePageController: UIViewController, PageProtocol, VIMVideoPlayerViewDelegate {

	private static let timeFormatter: NSDateFormatter = {
		let formatter = NSDateFormatter()
		formatter.timeStyle = .MediumStyle
		formatter.dateStyle = .ShortStyle
		return formatter }()

	private static let relativeFormatter: NSDateComponentsFormatter = {
		let formatter = NSDateComponentsFormatter()
		formatter.allowedUnits = [.Day, .Hour, .Minute]
		formatter.zeroFormattingBehavior = .DropAll
		formatter.unitsStyle = .Full
		return formatter }()

	var page: Int!
    var sample: Sample! {
        didSet {
            media = NSURL(string: sample.media.path!, relativeToURL: PartyUpConstants.ContentDistribution)
        }
    }
	var ad: NSURL?

	@IBOutlet weak var videoFailed: UILabel!
	@IBOutlet weak var videoWaiting: UIActivityIndicatorView!
	@IBOutlet weak var commentLabel: UITextView!
	@IBOutlet weak var timeLabel: UILabel!
	@IBOutlet weak var videoProgress: DACircularProgressView!
	@IBOutlet weak var videoReview: UIView!
	@IBOutlet weak var voteLabel: UILabel!
	@IBOutlet var voteButtons: [UIButton]!

	private let playView = VIMVideoPlayerView()
	private var displayRelativeTime = true
    private var media: NSURL?

	private func formatTime(time: NSDate, relative: Bool) -> String {
		if relative {
			let stale = NSUserDefaults.standardUserDefaults().doubleForKey(PartyUpPreferences.StaleSampleInterval)
            return SampleTastePageController.relativeFormatter.stringFromDate(time, toDate: NSDate(), classicThreshold: stale, postfix: true, substituteZero: true) ?? "WTF?"
		} else {
			return SampleTastePageController.timeFormatter.stringFromDate(time)
		}
	}

	@IBAction func toggleTimeFormat(sender: UITapGestureRecognizer) {
		displayRelativeTime = !displayRelativeTime
		timeLabel.text = formatTime(sample.time, relative: displayRelativeTime)
	}

    override func viewDidLoad() {
        super.viewDidLoad()

		timeLabel.text = formatTime(sample.time, relative: displayRelativeTime)
		
		if let comment = sample.comment {
			commentLabel.text = comment
		}

		updateVoteIndicators()

		playView.translatesAutoresizingMaskIntoConstraints = false
		playView.layer.cornerRadius = 10
		playView.layer.masksToBounds = true
		playView.delegate = self
		playView.player.enableTimeUpdates()
		playView.player.looping = true

		videoReview.addSubview(playView)

		videoReview.addConstraint(NSLayoutConstraint(
			item: playView,
			attribute: .CenterX,
			relatedBy: .Equal,
			toItem: videoReview,
			attribute: .CenterX,
			multiplier: 1.0,
			constant: 0))

		videoReview.addConstraint(NSLayoutConstraint(
			item: playView,
			attribute: .Width,
			relatedBy: .Equal,
			toItem: videoReview,
			attribute: .Width,
			multiplier: 1.0,
			constant: 0))

		videoReview.addConstraint(NSLayoutConstraint(
			item: playView,
			attribute: .Height,
			relatedBy: .Equal,
			toItem: playView,
			attribute: .Width,
			multiplier: 1.0,
			constant: 0))

		videoReview.addConstraint(NSLayoutConstraint(
			item: playView,
			attribute: .Top,
			relatedBy: .Equal,
			toItem: videoReview,
			attribute: .Top,
			multiplier: 1.0,
			constant: 0))

		if let media = media {
			playView.player.setURL(media)
		}

		let notify = NSNotificationCenter.defaultCenter()
		notify.addObserver(self, selector: #selector(SampleTastePageController.observeApplicationBecameActive), name: UIApplicationDidBecomeActiveNotification, object: nil)
		notify.addObserver(self, selector: #selector(SampleTastePageController.observeApplicationEnterBackground), name: UIApplicationDidEnterBackgroundNotification, object: nil)
		notify.addObserver(self, selector: #selector(SampleTastePageController.updateVoteIndicators), name: Sample.RatingUpdateNotification, object: sample)
		notify.addObserver(self, selector: #selector(SampleTastePageController.updateVoteIndicators), name: Sample.VoteUpdateNotification, object: sample)
	}

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
		playView.player.pause()
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		navigationController?.navigationBar.topItem?.title = sample.event.name
		playView.player.play()

		Flurry.logEvent("Sample_Tasted", withParameters: ["timestamp" : sample.time.description], timed: true)
	}

	override func viewDidDisappear(animated: Bool) {
		super.viewDidDisappear(animated)
		playView.player.pause()
		var duration = 0.0
		if let time = playView.player.player.currentItem?.duration {
			duration = CMTimeGetSeconds(time)
		}
		Flurry.endTimedEvent("Sample_Tasted", withParameters: ["duration" : duration])
	}

	func updateVoteIndicators() {
		voteButtons[0].selected = sample.vote == .Down
		voteButtons[1].selected = sample.vote == .Up

		voteLabel.text = "\(sample.rating[0] - sample.rating[1])"
	}

	func shareSampleVia(service: String) {
		let message = NSLocalizedString("#PartyUP at \(sample.event.name)", comment: "Share video message prefix")
		presentShareSheetOn(self, viaService: service, withMessage: message, url: media, image: nil)
	}

	@IBAction func placeVote(sender: UIButton) {
		let vote = sender.selected ? Vote.Meh : Vote(rawValue: sender.tag)!
		sample.setVote(vote)
		voteButtons.forEach { button in button.selected = false }
        Flurry.logEvent("Vote_Cast", withParameters: ["vote" : vote.rawValue])
	}

	func purveyOffensive() {
        let user = UIDevice.currentDevice().identifierForVendor!
		let options = UIAlertController(
			title: NSLocalizedString("Offensive Material", comment: "Offensive material alert title"),
			message: NSLocalizedString("Give this offensive video the boot!", comment: "Offensive material alert message"),
			preferredStyle: .Alert)
		let report = UIAlertAction(
			title: NSLocalizedString("Report Offensive Video", comment: "Report offensive alert action"),
            style: .Destructive) { _ in self.sample.setVote(Vote.Down, andFlag: true); Flurry.logEvent("Offensive_Sample_Reported", withParameters: [ "reporter" : user, "sample" : self.sample.media.description]) }
		let mute = UIAlertAction(
			title: NSLocalizedString("Mute Contributor", comment: "Mute contributor alert action"),
            style: .Destructive) { _ in Defensive.shared.mute(self.sample.user); Flurry.logEvent("Offensive_User_Muted", withParameters: ["reporter" : user, "offender" : self.sample.user.UUIDString]) }
		let cancel = UIAlertAction(
			title: NSLocalizedString("Cancel", comment: "Cancel alert action"),
			style: .Cancel) { _ in }
		options.addAction(report)
		options.addAction(mute)
		options.addAction(cancel)

		presentViewController(options, animated: true, completion: nil)
	}

	@IBAction func purveyOptions(sender: UIButton) {
		let options = UIAlertController(
			title: NSLocalizedString("Share or Report", comment: "Share or Report alert title"),
			message: NSLocalizedString("Share this video or report it as offensive.", comment: "Share and Report message"),
			preferredStyle: .ActionSheet)
		let twitter = UIAlertAction(
			title: NSLocalizedString("Share Video via Twitter", comment: "Share via Twitter alert action"),
			style: .Default) { _ in self.shareSampleVia(SLServiceTypeTwitter) }
		let facebook = UIAlertAction(
			title: NSLocalizedString("Share Video via Facebook", comment: "Share via Facebook alert action"),
			style: .Default) { _ in self.shareSampleVia(SLServiceTypeFacebook) }
		let report = UIAlertAction(
			title: NSLocalizedString("Report Offensive Video", comment: "Report offensive alert action"),
			style: .Destructive) { _ in self.purveyOffensive() }
		let cancel = UIAlertAction(
			title: NSLocalizedString("Cancel", comment: "Cancel alert action"),
			style: .Cancel) { _ in }
		options.addAction(twitter)
		options.addAction(facebook)
		options.addAction(report)
		options.addAction(cancel)

		if let pop = options.popoverPresentationController {
			pop.sourceView = sender
			pop.sourceRect = sender.bounds
		}

		presentViewController(options, animated: true, completion: nil)
	}

	// MARK: Player

	func videoPlayerView(videoPlayerView: VIMVideoPlayerView!, timeDidChange cmTime: CMTime) {
		let cmTotal = videoPlayerView.player.player.currentItem?.duration ?? CMTimeMakeWithSeconds(0, 1)
		videoProgress.setProgress(CGFloat(CMTimeGetSeconds(cmTime)/CMTimeGetSeconds(cmTotal)), animated: true)
	}

	func videoPlayerView(videoPlayerView: VIMVideoPlayerView!, didFailWithError error: NSError!) {
		videoWaiting.stopAnimating()
		videoFailed.hidden = false
		Flurry.logError("Sample_Play_Error", message: "Video playback failed.", error: error)
	}
    
    func videoPlayerViewIsReadyToPlayVideo(videoPlayerView: VIMVideoPlayerView!) {
        videoWaiting.stopAnimating()
    }

	// MARK: - Application Lifecycle

	func observeApplicationBecameActive() {
		if let pvc = parentViewController as? UIPageViewController where pvc.viewControllers?.first == self {
			playView.player.play()
		}
	}

	func observeApplicationEnterBackground() {
		playView.player.pause()
	}

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if let avc = segue.destinationViewController as? AdvertisingOverlayController {
			avc.url = ad
		}
	}
}
