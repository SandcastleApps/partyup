//
//  ObserveSampleController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-22.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit
import AVFoundation

class ObserveSampleController: UIViewController {

	private let playLayer = AVPlayerLayer()
	private var playControl: AVPlayer?

	var sample: Sample? {
		didSet {
			resetPlayer()
		}
	}

	@IBOutlet weak var movieView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

		playLayer.frame = movieView.layer.bounds
		playLayer.videoGravity = AVLayerVideoGravityResizeAspect
		movieView.layer.addSublayer(playLayer)

		NSNotificationCenter.defaultCenter().addObserver(self,
			selector: Selector("playbackReachedEndNotification:"),
			name: AVPlayerItemDidPlayToEndTimeNotification,
			object: nil)

		play()
    }

	func resetPlayer() {
		playControl?.removeObserver(self, forKeyPath: "status", context: UnsafeMutablePointer<Void>())
		playControl = nil

		if let sample = sample {
			let url = PartyUpConstants.ContentDistribution.URLByAppendingPathComponent(sample.media.path!)
			playControl = AVPlayer(URL: url)
			playControl?.addObserver(self, forKeyPath: "status", options: .Initial, context: UnsafeMutablePointer<Void>())
			playLayer.player = playControl
		}
	}

	deinit {
		sample = nil
		resetPlayer()
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

	func play() {
		if playControl?.status == .ReadyToPlay {
			playControl?.play()
		} else if playControl?.status == .Failed {
			NSLog("Failed to load")
		}
	}

	override func prefersStatusBarHidden() -> Bool {
		return true
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		playLayer.frame = movieView.bounds
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

	override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {

		if keyPath == "status" {
			dispatch_async(dispatch_get_main_queue()) { self.play() }
		}
	}

	@objc func playbackReachedEndNotification(notification: NSNotification) {
		playControl?.seekToTime(kCMTimeZero)
		playControl?.play()
	}
}
