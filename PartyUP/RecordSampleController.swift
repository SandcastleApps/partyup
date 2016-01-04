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
import Flurry_iOS_SDK

class RecordSampleController: UIViewController, PBJVisionDelegate {

	@IBOutlet weak var recordButton: UIButton!
	@IBOutlet weak var timerBar: DACircularProgressView!
	@IBOutlet weak var preview: UIView!
	@IBOutlet weak var naviBar: UINavigationBar!
    @IBOutlet weak var recordStatus: UILabel!

	var transitionStartY: CGFloat = 0.0

	private let maxVideoDuration = 10.0
	private let minVideoDuration = 5.0
	let vision = PBJVision.sharedInstance()
	var timer: NSTimer!

    override func viewDidLoad() {
        super.viewDidLoad()

		naviBar.topItem?.titleView = PartyUpConstants.TitleLogo()

		timerBar.trackTintColor = UIColor.lightGrayColor()
		timerBar.roundedCorners = 1

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

    // MARK: - Camera Control

	@IBAction func torchControl(sender: UIBarButtonItem) {
		vision.flashMode = vision.flashMode == .Off ? .On : .Off

		if vision.flashMode == .On {
			sender.image = UIImage(named: "FlashOn")
		} else {
			sender.image = UIImage(named: "FlashOff")
		}
	}

	@IBAction func toggleCamera(sender: UIBarButtonItem?) {
		switch vision.cameraDevice {
		case .Back:
			if vision.isCameraDeviceAvailable(.Front) {
				vision.cameraDevice = .Front
			}
		case .Front:
			if vision.isCameraDeviceAvailable(.Back) {
				vision.cameraDevice = .Back
			}
		}
		Flurry.logEvent("Selfie_Toggle", withParameters: ["camera" : "\(vision.cameraDevice)"])
	}

	func resetTimerBar() {
		timer?.invalidate()
		timerBar.progress = 0.0
		timerBar.progressTintColor = UIColor(red: 0.93, green: 0.02, blue: 0.54, alpha: 1.0)
	}

	// MARK: - Recording

	func observeTimerInterval() {
		timerBar.progress = CGFloat(vision.capturedVideoSeconds / maxVideoDuration)

		if timerBar.progress >= 0.5 {
			timerBar.progressTintColor = UIColor(red: 0.98, green: 0.66, blue: 0.26, alpha: 1.0)
		}

		if timerBar.progress >= 1.0 {
			endRecording(false)
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

    func endRecording(abandon: Bool = false) {
        if vision.capturedVideoSeconds < minVideoDuration || abandon {
            vision.cancelVideoCapture()
        } else {
            vision.endVideoCapture()
        }

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
    
    @IBAction func stopRecording() {
        endRecording(false)
    }
    
    @IBAction func abandonRecording() {
        endRecording(true)
    }

	// MARK: - PBJ Delegate

	func vision(vision: PBJVision, capturedVideo videoDict: [NSObject : AnyObject]?, error: NSError?) {
        resetTimerBar()
        
		if let err = error {
            if err.domain == PBJVisionErrorDomain && err.code == PBJVisionErrorType.Cancelled.rawValue {
                Flurry.logEvent("Truncated_Sample")
            } else {
                Flurry.logError("Video_Capture_Error", message: error?.localizedDescription, error: error)
            }
        } else {
			if let out = videoDict?[PBJVisionVideoPathKey] as? String {
                host?.recordedSample(NSURL(fileURLWithPath: out))
			}
        }
	}

	func vision(vision: PBJVision, willStartVideoCaptureToFile fileName: String) -> String {
		dispatch_async(dispatch_get_main_queue()) {
			self.resetTimerBar()
			self.timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("observeTimerInterval"), userInfo: nil, repeats: true)
		}

		return fileName
	}

	// MARK: - Hosted

	@IBAction func cancelRecording(sender: UIBarButtonItem) {
		if vision.cameraDevice != .Back {
			toggleCamera(nil)
		}
		
		host?.recordedSample(nil)
		Flurry.logEvent("Sample_Cancelled")
	}

	private weak var host: BakeRootController?

	override func didMoveToParentViewController(parent: UIViewController?) {
		host = parent as? BakeRootController
		if host == nil {
			resetTimerBar()

			if vision.cameraDevice != .Back {
				toggleCamera(nil)
			}
		}
	}
}

extension RecordSampleController: UIBarPositioningDelegate {
	func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
		return .TopAttached
	}
}
