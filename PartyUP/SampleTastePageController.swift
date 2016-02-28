//
//  SampleTastePageController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-24.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit
import Player
import Social
import DACircularProgress
import Flurry_iOS_SDK

class SampleTastePageController: UIViewController, PageProtocol, PlayerDelegate {

	private static let timeFormatter: NSDateFormatter = { let formatter = NSDateFormatter(); formatter.timeStyle = .MediumStyle; formatter.dateStyle = .ShortStyle; return formatter }()

	var page: Int!
    var sample: Sample! {
        didSet {
            media = NSURL(string: sample.media.path!, relativeToURL: PartyUpConstants.ContentDistribution)
        }
    }

	@IBOutlet weak var videoWaiting: UIActivityIndicatorView!
	@IBOutlet weak var commentLabel: UITextView!
	@IBOutlet weak var timeLabel: UILabel!
	@IBOutlet weak var videoProgress: DACircularProgressView!
	@IBOutlet weak var videoReview: UIView!
	@IBOutlet weak var voteLabel: UILabel!
	@IBOutlet var voteButtons: [UIButton]!

	private let player = Player()
	private var timer: NSTimer?
	private var tick: Double = 0.0
	private let tickInc: Double = 0.10
	private var visible = false
	private var displayRelativeTime = true
    private var media: NSURL?

	private func formatTime(time: NSDate, relative: Bool) -> String {
		if relative {
			let stale = NSDate(timeIntervalSinceNow: -NSUserDefaults.standardUserDefaults().doubleForKey(PartyUpPreferences.StaleSampleInterval))
			if stale.compare(sample.time) == .OrderedAscending {
				return formatRelativeDateFrom(time)
			} else {
				return NSLocalizedString("Classic", comment: "Stale time display")
			}
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

		player.view.translatesAutoresizingMaskIntoConstraints = false
		player.view.layer.cornerRadius = 10
		player.view.layer.masksToBounds = true

		addChildViewController(player)
		videoReview.addSubview(player.view)
		player.didMoveToParentViewController(self)

		videoReview.addConstraint(NSLayoutConstraint(
			item: player.view,
			attribute: .CenterX,
			relatedBy: .Equal,
			toItem: videoReview,
			attribute: .CenterX,
			multiplier: 1.0,
			constant: 0))

		videoReview.addConstraint(NSLayoutConstraint(
			item: player.view,
			attribute: .Width,
			relatedBy: .Equal,
			toItem: videoReview,
			attribute: .Width,
			multiplier: 1.0,
			constant: 0))

		videoReview.addConstraint(NSLayoutConstraint(
			item: player.view,
			attribute: .Height,
			relatedBy: .Equal,
			toItem: player.view,
			attribute: .Width,
			multiplier: 1.0,
			constant: 0))

		videoReview.addConstraint(NSLayoutConstraint(
			item: player.view,
			attribute: .Top,
			relatedBy: .Equal,
			toItem: videoReview,
			attribute: .Top,
			multiplier: 1.0,
			constant: 0))

		player.setUrl(media!)

		let notify = NSNotificationCenter.defaultCenter()
		notify.addObserver(self, selector: Selector("observeApplicationBecameActive"), name: UIApplicationDidBecomeActiveNotification, object: nil)
		notify.addObserver(self, selector: Selector("updateVoteIndicators"), name: Sample.RatingUpdateNotification, object: sample)
		notify.addObserver(self, selector: Selector("updateVoteIndicators"), name: Sample.VoteUpdateNotification, object: sample)
	}

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
		player.stop()
		timer?.invalidate()
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		visible = true

		navigationController?.navigationBar.topItem?.title = sample.event.name
		player.delegate = self
		if player.bufferingState == .Ready {
			player.playFromBeginning()
		}

		Flurry.logEvent("Sample_Tasted", withParameters: ["timestamp" : sample.time.description], timed: true)
	}

	override func viewDidDisappear(animated: Bool) {
		super.viewDidDisappear(animated)
		player.stop()
		timer?.invalidate()
		player.delegate = nil
		Flurry.endTimedEvent("Sample_Tasted", withParameters: ["duration" : player.maximumDuration.description])
		visible = false
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

	func reportOffensive() {
		sample.setVote(Vote.Down, andFlag: true)
	}

	func muteOffender() {
		Defensive.shared.mute(sample.user)
	}

	@IBAction func placeVote(sender: UIButton) {
		let vote = sender.selected ? Vote.Meh : Vote(rawValue: sender.tag)!
		sample.setVote(vote)
		voteButtons.forEach { button in button.selected = false }
	}

	@IBAction func purveyOptions(sender: UIButton) {
		let options = UIAlertController(
			title: NSLocalizedString("Share and Report", comment: "Share and Report alert title"),
			message: nil,
			preferredStyle: .ActionSheet)
		let twitter = UIAlertAction(
			title: NSLocalizedString("Share Video via Twitter", comment: "Share via Twitter alert action"),
			style: .Default) { _ in self.shareSampleVia(SLServiceTypeTwitter) }
		let facebook = UIAlertAction(
			title: NSLocalizedString("Share Video via Facebook", comment: "Share via Facebook alert action"),
			style: .Default) { _ in self.shareSampleVia(SLServiceTypeFacebook) }
		let report = UIAlertAction(
			title: NSLocalizedString("Report Offensive Video", comment: "Report offensive alert action"),
			style: .Destructive) { _ in self.reportOffensive() }
		let mute = UIAlertAction(
			title: NSLocalizedString("Mute Contributor", comment: "Mute contributor alert action"),
			style: .Destructive) { _ in self.muteOffender() }
		let cancel = UIAlertAction(
			title: NSLocalizedString("Cancel", comment: "Cancel alert action"),
			style: .Cancel) { _ in }
		options.addAction(twitter)
		options.addAction(facebook)
		options.addAction(report)
		options.addAction(mute)
		options.addAction(cancel)

		if let pop = options.popoverPresentationController {
			pop.sourceView = sender
			pop.sourceRect = sender.bounds
		}

		presentViewController(options, animated: true, completion: nil)
	}

	// MARK: Player

	func playerPlaybackWillStartFromBeginning(player: Player) {
		tick = 0.0
		videoProgress.setProgress(CGFloat(tick), animated: false)
		timer?.invalidate()
		timer = NSTimer.scheduledTimerWithTimeInterval(tickInc, target: self, selector: Selector("playerTimer"), userInfo: nil, repeats: true)
	}

	func playerPlaybackDidEnd(player: Player) {
		videoProgress.setProgress(1.0, animated: false)
		player.playFromBeginning()
	}

	func playerReady(player: Player) {
		videoWaiting.stopAnimating()
		if player.playbackState != .Playing {
			player.playFromBeginning()
		}
	}

	func playerPlaybackStateDidChange(player: Player) {
		switch player.playbackState! {
		case .Failed:
			NSLog("Sample playback failed on page \(page) \(sample)")
			fallthrough
		case .Paused:
			fallthrough
		case .Stopped:
			timer?.invalidate()
		case .Playing:
			break
		}
	}

	func playerBufferingStateDidChange(player: Player) {
		switch player.bufferingState {
		case .Some(.Delayed):
			NSLog("Sample buffering delayed on page \(page) \(sample)")
		default:
			break
		}
	}

	// MARK: Timer

	func playerTimer() {
		tick += tickInc
		videoProgress.setProgress(CGFloat(tick)/CGFloat(player.maximumDuration), animated: false)
	}

	// MARK: - Application Lifecycle

	func observeApplicationBecameActive() {
		if player.playbackState == .Paused && visible {
			player.playFromCurrentTime()
			timer = NSTimer.scheduledTimerWithTimeInterval(tickInc, target: self, selector: Selector("playerTimer"), userInfo: nil, repeats: true)
		}
	}
}
