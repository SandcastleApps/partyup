//
//  SampleTastePageController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-24.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit
import Player
import DACircularProgress
import Flurry_iOS_SDK

class SampleTastePageController: UIViewController, PageProtocol, PlayerDelegate {

	private static let timeFormatter: NSDateFormatter = { let formatter = NSDateFormatter(); formatter.timeStyle = .MediumStyle; formatter.dateStyle = .NoStyle; return formatter }()

	var page: Int!
	var sample: Sample!

	@IBOutlet weak var videoWaiting: UIActivityIndicatorView!
	@IBOutlet weak var commentLabel: UITextView!
	@IBOutlet weak var timeLabel: UILabel!
	@IBOutlet weak var videoProgress: DACircularProgressView!
	@IBOutlet weak var videoReview: UIView!

	private let player = Player()
	private var timer: NSTimer?
	private var tick: Double = 0.0
	private let tickInc: Double = 0.10
	private var visible = false
	private var displayRelativeTime = true

	private func formatTime(time: NSDate, relative: Bool) -> String {
		if let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian) where relative {
			let components = calendar.components([NSCalendarUnit.Hour, NSCalendarUnit.Minute],
				fromDate: time,
				toDate: NSDate(),
				options: [])

			var stringy = ""

			switch components.hour {
			case 1:
				stringy = NSLocalizedString("1 hour ", comment: "Relative sample hour, be sure to leave the space at the end")
			case let x where x > 1:
				stringy = NSLocalizedString("\(x) hours ", comment: "Relative sampe hours, be sure to leave the space at the end")
			default:
				stringy = ""
			}

			switch components.minute {
			case 1:
				stringy += NSLocalizedString("1 minute ", comment: "Relative sample minute, be sure to leave space at end")
			case let x where x > 1:
				stringy += NSLocalizedString("\(x) minutes ", comment: "Relative sample minutes, be sure to leave space at end")
			default:
				stringy += ""
			}

			stringy += stringy.isEmpty ? NSLocalizedString("very fresh", comment: "Samples less than a minue old") : NSLocalizedString("ago", comment:"Samples more than a minute old")

			return stringy
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

		player.setUrl(PartyUpConstants.ContentDistribution.URLByAppendingPathComponent(sample.media.path!))

		NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("observeApplicationBecameActive"), name: UIApplicationDidBecomeActiveNotification, object: nil)
	}

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
		player.stop()
		timer?.invalidate()
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		visible = true

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
