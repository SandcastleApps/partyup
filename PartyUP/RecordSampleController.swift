//
//  RecordSampleController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-25.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit
import DACircularProgress
import PBJVision

class RecordSampleController: UIViewController, PBJVisionDelegate {

	@IBOutlet weak var recordButton: UIButton!
	@IBOutlet weak var timerBar: DACircularProgressView!
	@IBOutlet weak var preview: UIView!
	@IBOutlet weak var naviBar: UINavigationBar!

	var transitionStartY: CGFloat = 0.0

	private let maxVideoDuration = 10.0
	private let minVideoDuration = 5.0
	let vision = PBJVision.sharedInstance()
	var timer: NSTimer!

    override func viewDidLoad() {
        super.viewDidLoad()

		naviBar.topItem?.titleView = PartyUpConstants.TitleLogo()

		let pvLayer = vision.previewLayer
		pvLayer.frame = preview.bounds
		pvLayer.cornerRadius = 10
		pvLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
		preview.layer.addSublayer(pvLayer)

		vision.delegate = self
		vision.cameraMode = .Video
		vision.cameraOrientation = .Portrait
		vision.focusMode = .ContinuousAutoFocus
		vision.outputFormat = .Square
		vision.captureSessionPreset = NSUserDefaults.standardUserDefaults().stringForKey(PartyUpPreferences.VideoQuality) ?? AVCaptureSessionPresetMedium
    }

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		vision.startPreview()

		recordButton.hidden = true
		preview.hidden = true
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		recordButton.transform = CGAffineTransformMakeScale(0.1, 0.1)
		preview.transform = CGAffineTransformMakeTranslation(0, transitionStartY - preview.frame.origin.y)

		recordButton.hidden = false
		preview.hidden = false

		UIView.animateWithDuration(0.5,
			delay: 0,
			usingSpringWithDamping: 0.85,
			initialSpringVelocity: 10,
			options: [],
			animations: {
				self.recordButton.transform = CGAffineTransformIdentity
				self.preview.transform = CGAffineTransformIdentity
			},
			completion: nil)
	}

	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		vision.stopPreview()
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		vision.previewLayer.frame = preview.bounds
	}

    // MARK: - Navigation
	@IBAction func torchControl(sender: UIBarButtonItem) {
		vision.flashMode = vision.flashMode == .Off ? .On : .Off

		if vision.flashMode == .On {
			sender.image = UIImage(named: "FlashOn")
		} else {
			sender.image = UIImage(named: "FlashOff")
		}
	}

	func resetTimerBar() {
		timer?.invalidate()
		timerBar.progress = 0.0
		timerBar.progressTintColor = UIColor.yellowColor()
	}

	// MARK: - Recording

	func observeTimerInterval() {
		timerBar.progress = CGFloat(vision.capturedVideoSeconds / maxVideoDuration)

		if timerBar.progress >= 0.5 {
			timerBar.progressTintColor = UIColor.greenColor()
		}

		if timerBar.progress >= 1.0 {
			stopRecording()
		}
	}

	@IBAction func startRecording() {
		vision.startVideoCapture()

		UIView.animateWithDuration(0.5,
			delay: 0,
			usingSpringWithDamping: 0.85,
			initialSpringVelocity: 10,
			options: [],
			animations: {
				self.recordButton.transform = CGAffineTransformMakeScale(1.2, 1.2)
				self.timerBar.transform = CGAffineTransformMakeScale(1.2, 1.2)
			},
			completion: nil)
	}

	@IBAction func stopRecording() {
		vision.endVideoCapture()

		UIView.animateWithDuration(0.5,
			delay: 0,
			usingSpringWithDamping: 0.85,
			initialSpringVelocity: 10,
			options: [],
			animations: {
				self.recordButton.transform = CGAffineTransformIdentity
				self.timerBar.transform = CGAffineTransformIdentity
			},
			completion: nil)
	}

	// MARK: - PBJ Delegate

	func vision(vision: PBJVision, capturedVideo videoDict: [NSObject : AnyObject]?, error: NSError?) {
		if error == nil {
			if let out = videoDict?[PBJVisionVideoPathKey] as? String {
				if let duration = videoDict?[PBJVisionVideoCapturedDurationKey] as? Double where duration >= minVideoDuration {
					host?.recordedSample(NSURL(fileURLWithPath: out))
				} else {
					if let error = try? NSFileManager.defaultManager().removeItemAtPath(out) {
						NSLog("Failed to delete cancelled video with error: \(error)")
					}
				}
			}
		}

		resetTimerBar()
	}

	func vision(vision: PBJVision, willStartVideoCaptureToFile fileName: String) -> String {
		dispatch_async(dispatch_get_main_queue()) {
			self.resetTimerBar()
			self.timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: Selector("observeTimerInterval"), userInfo: nil, repeats: true)
		}

		return fileName
	}

	// MARK: - Hosted

	@IBAction func cancelRecording(sender: UIBarButtonItem) {
		host?.recordedSample(nil)
	}

	private weak var host: BakeRootController?

	override func didMoveToParentViewController(parent: UIViewController?) {
		host = parent as? BakeRootController
		if host == nil {
			resetTimerBar()
		}
	}
}

extension RecordSampleController: UIBarPositioningDelegate {
	func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
		return .TopAttached
	}
}
