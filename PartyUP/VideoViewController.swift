//
//  VideoViewController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-22.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit
import AVFoundation

class VideoViewController: UIViewController {

	var player: AVPlayer? {
		willSet {
			if let time = timeObserver {
				player?.removeTimeObserver(time)
			}
			player?.removeObserver(self, forKeyPath: "status", context: UnsafeMutablePointer<Void>())
			NSNotificationCenter.defaultCenter().removeObserver(self, name: "playbackReachedEndNotification", object: player?.currentItem)
		}

		didSet {
			player?.addPeriodicTimeObserverForInterval(CMTime(seconds: 1, preferredTimescale: 1), queue: nil, usingBlock: { (time) in
				if let player = self.player, item = player.currentItem {
					self.videoProgress.setProgress(Float(player.currentTime().seconds / CMTimeGetSeconds(item.duration)), animated: false)
				}})
			player?.addObserver(self, forKeyPath: "status", options: .Initial, context: UnsafeMutablePointer<Void>())
			playLayer.player = player

			NSNotificationCenter.defaultCenter().addObserver(self,
				selector: Selector("playbackReachedEndNotification"),
				name: AVPlayerItemDidPlayToEndTimeNotification,
				object: player?.currentItem)
		}
	}

	var loop: Bool = false
	var rate: Float = 0.0

	@IBOutlet weak var videoView: UIView!
	@IBOutlet weak var videoProgress: UIProgressView!

	private let playLayer = AVPlayerLayer()
	private var timeObserver: AnyObject?

    override func viewDidLoad() {
        super.viewDidLoad()

		playLayer.frame = videoView.layer.bounds
		playLayer.videoGravity = AVLayerVideoGravityResizeAspect
		videoView.layer.addSublayer(playLayer)

		NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("applicationDidBecomeActiveNotification"), name: UIApplicationDidBecomeActiveNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("applicationWillResignActiveNotification"), name: UIApplicationWillResignActiveNotification, object: nil)
    }

	func applicationDidBecomeActiveNotification() {
		play(rate)
	}

	func applicationWillResignActiveNotification() {
		play(0.0)
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		play(rate)
	}

	override func viewDidDisappear(animated: Bool) {
		super.viewDidDisappear(animated)
		play(0.0)
	}

	deinit {
		if let time = timeObserver {
			player?.removeTimeObserver(time)
		}
		player?.removeObserver(self, forKeyPath: "status", context: UnsafeMutablePointer<Void>())
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

	private func play(rate: Float = 1.0) {

		if let player = player {
			switch player.status {
			case .ReadyToPlay:
				player.rate = rate
			case .Failed:
				//handle appropriately
				break
			case .Unknown:
				break
			}
		}
	}

	override func prefersStatusBarHidden() -> Bool {
		return true
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		playLayer.frame = view.bounds
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

	override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {

		if keyPath == "status" {
			dispatch_async(dispatch_get_main_queue()) { if self.view.window != nil { self.play() } }
		}
	}

	func playbackReachedEndNotification() {
		if loop {
			player?.seekToTime(kCMTimeZero)
			play(rate)
		}
	}
}
