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

class SampleTastePageController: UIViewController, PlayerDelegate {

	private static let timeFormatter: NSDateFormatter = { let formatter = NSDateFormatter(); formatter.timeStyle = .MediumStyle; formatter.dateStyle = .NoStyle; return formatter }()

	var page: Int!
	var sample: Sample!

	@IBOutlet weak var commentLabel: UILabel!
	@IBOutlet weak var timeLabel: UILabel!
	@IBOutlet weak var commentBackdrop: UIVisualEffectView!
	@IBOutlet weak var videoProgress: DACircularProgressView!

	private let player = Player()
	private var timer: NSTimer!
	private var tick: Double = 0.0
	private let tickInc: Double = 0.5

    override func viewDidLoad() {
        super.viewDidLoad()

		timeLabel.text = SampleTastePageController.timeFormatter.stringFromDate(sample.time)
		if let comment = sample.comment {
			commentLabel.text = comment
			commentLabel.hidden = false
			commentBackdrop.hidden = false
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

		player.setUrl(PartyUpConstants.ContentDistribution.URLByAppendingPathComponent(sample.media.path!))
    }

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		player.playFromBeginning()
	}

	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		player.stop()
	}

	// MARK: Player

	func playerPlaybackWillStartFromBeginning(player: Player) {
		tick = 0.0
		videoProgress.setProgress(CGFloat(tick), animated: false)
		timer = NSTimer.scheduledTimerWithTimeInterval(tickInc, target: self, selector: Selector("playerTimer"), userInfo: nil, repeats: true)
	}

	func playerPlaybackDidEnd(player: Player) {
		videoProgress.setProgress(1.0, animated: false)
		timer.invalidate()
		player.playFromBeginning()
	}

	func playerReady(player: Player) {
	}

	func playerPlaybackStateDidChange(player: Player) {
		if player.playbackState != .Playing {
			timer.invalidate()
		}
	}

	func playerBufferingStateDidChange(player: Player) {
	}

	// MARK: Timer

	func playerTimer() {
		tick += tickInc
		videoProgress.setProgress(CGFloat(tick)/CGFloat(player.maximumDuration), animated: false)
	}
}
