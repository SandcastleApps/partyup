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
import SCLAlertView

class SampleTastePageController: UIViewController, PageProtocol, VIMVideoPlayerViewDelegate {

	private static let timeFormatter: NSDateFormatter = {
		let formatter = NSDateFormatter()
		formatter.timeStyle = .MediumStyle
		formatter.dateStyle = .ShortStyle
		return formatter }()

	private static let relativeFormatter: NSDateComponentsFormatter = {
		let formatter = NSDateComponentsFormatter()
		formatter.allowedUnits = [.Month, .WeekOfMonth, .Day, .Hour, .Minute]
		formatter.maximumUnitCount = 1
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
	@IBOutlet weak var shareView: UIView!
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
            return SampleTastePageController.relativeFormatter.stringFromDate(time, toDate: NSDate(), classicThreshold: stale, postfix: true, substituteZero: NSLocalizedString("very fresh", comment: "Relative less than a minute old")) ?? "WTF?"
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
        
        let text = NSMutableAttributedString()
        
        if let alias = sample.alias {
            text.appendAttributedString(NSAttributedString(string: alias + "  ", attributes: [NSFontAttributeName:UIFont.boldSystemFontOfSize(16)]))
        }
		
		if let comment = sample.comment {
			 text.appendAttributedString(NSAttributedString(string: comment, attributes: [NSFontAttributeName:UIFont.systemFontOfSize((16))]))
		}
        
        commentLabel.attributedText = text

		let line: CAGradientLayer = CAGradientLayer()
//		line.shadowColor = UIColor(r: 251, g: 176, b: 64, alpha: 255).CGColor
//		line.shadowOffset = CGSize(width: 1.0, height: 1.0)
//		line.shadowRadius = 1.0
//		line.shadowOpacity = 1.0
		line.startPoint = CGPoint(x: 0.0, y: 0.5)
		line.endPoint = CGPoint(x: 1.0, y: 0.5)
		line.colors = [UIColor(r: 251, g: 176, b: 64, alpha: 255).CGColor, UIColor(r: 236, g: 0, b: 140, alpha: 255).CGColor, UIColor(r: 251, g: 176, b: 64, alpha: 255).CGColor]
		shareView.layer.insertSublayer(line, atIndex: 0)

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
        
        tutorial.start(self)

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

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		shareView.layer.sublayers?[0].frame = CGRect(x: 10.0, y: shareView.bounds.height, width: shareView.bounds.width - 20.0, height: 0.5)
	}

	func updateVoteIndicators() {
		voteButtons[0].selected = sample.vote == .Down
		voteButtons[1].selected = sample.vote == .Up

		voteLabel.text = "\(sample.rating[0] - sample.rating[1])"
	}

	@IBAction func shareSampleVia(sender: UIButton) {
		var service: String
		switch sender.tag {
		case 101:
			service = SLServiceTypeTwitter
		case 102:
			service = SLServiceTypeFacebook
		default:
			return
		}
		let message = NSLocalizedString("#PartyUP at \(sample.event.name)", comment: "Share video message prefix")
		presentShareSheetOn(self, viaService: service, withMessage: message, url: media, image: nil)
	}

	@IBAction func placeVote(sender: UIButton) {
		let vote = sender.selected ? Vote.Meh : Vote(rawValue: sender.tag)!
		placeVote(vote)
		voteButtons.forEach { button in button.selected = false }
	}

	func placeVote(vote: Vote, andFlag flag: Bool = false) {
		if AuthenticationManager.shared.isLoggedIn {
			sample.setVote(vote, andFlag: flag)
			Flurry.logEvent("Vote_Cast", withParameters: ["vote" : vote.rawValue])
			if flag {
				let user = AuthenticationManager.shared.identity!
				Flurry.logEvent("Offensive_Sample_Reported", withParameters: [ "reporter" : user, "sample" : self.sample.media.description])
			}
		} else {
			AuthenticationFlow.shared.startOnController(self).addAction { manager in
				if manager.isLoggedIn { self.placeVote(vote, andFlag: flag) } }
		}
	}

	@IBAction func purveyOffensive(sender: UIButton) {
        let user = AuthenticationManager.shared.identity!
		let options = SCLAlertView()

		options.addButton(NSLocalizedString("Report Offensive Video", comment: "Report offensive alert action")) { self.placeVote(Vote.Down, andFlag: true)
		}
		options.addButton(NSLocalizedString("Mute Contributor", comment: "Mute contributor alert action")) { Defensive.shared.mute(self.sample.user); Flurry.logEvent("Offensive_User_Muted", withParameters: ["reporter" : user, "offender" : self.sample.user.UUIDString])
		}
		options.showInfo(NSLocalizedString("Offensive Material", comment: "Offensive material alert title"),
			subTitle: NSLocalizedString("Give this offensive video the boot!", comment: "Offensive material alert message"),
			closeButtonTitle: NSLocalizedString("Cancel", comment: "Cancel alert action"),
			colorStyle: 0xf77e56)
	}

	// MARK: - Player

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
    
    // MARK: - Tutorial
    
    private enum CoachIdentifier: Int {
        case Greeting = -3000, Time = 3001, Vote, Share, Comment
    }
    
    private static let availableCoachMarks = [
        TutorialMark(identifier: CoachIdentifier.Greeting.rawValue, hint: NSLocalizedString("See what's going on,\nswipe through videos!", comment: "Taste video greeting coachmark"))]
    
    private let tutorial = TutorialOverlayManager(marks: SampleTastePageController.availableCoachMarks)
}
