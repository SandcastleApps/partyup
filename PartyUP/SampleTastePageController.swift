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

class SampleTastePageController: UIViewController, PlayerDelegate {

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
				stringy = "1 hour "
			case let x where x > 1:
				stringy = "\(x) hours "
			default:
				stringy = ""
			}

			switch components.minute {
			case 1:
				stringy += "1 minute "
			case let x where x > 1:
				stringy += "\(x) minutes "
			default:
				stringy += ""
			}

			stringy += stringy.isEmpty ? "very fresh" : "ago"

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
    }

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		player.delegate = self
		player.playFromBeginning()

		Flurry.logEvent("Sample_Tasted", withParameters: ["timestamp" : sample.time.description], timed: true)
	}

	override func viewDidDisappear(animated: Bool) {
		super.viewDidDisappear(animated)
		player.stop()
		timer?.invalidate()
		player.delegate = nil
		Flurry.endTimedEvent("Sample_Tasted", withParameters: ["duration" : player.maximumDuration.description])
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
	}

	func playerPlaybackStateDidChange(player: Player) {
	}

	func playerBufferingStateDidChange(player: Player) {
	}

	// MARK: Timer

	func playerTimer() {
		tick += tickInc
		videoProgress.setProgress(CGFloat(tick)/CGFloat(player.maximumDuration), animated: false)
	}
}
