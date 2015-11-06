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

	let vision = PBJVision.sharedInstance()
	var timer: NSTimer!
	var venues: [Venue]?

    override func viewDidLoad() {
        super.viewDidLoad()

		let pvLayer = vision.previewLayer
		pvLayer.frame = preview.bounds
		pvLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
		preview.layer.addSublayer(pvLayer)

		vision.delegate = self
		vision.cameraMode = .Video
		vision.cameraOrientation = .Portrait
		vision.focusMode = .ContinuousAutoFocus
		vision.outputFormat = .Square
    }

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		vision.startPreview()
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
	}

	func resetTimerBar() {
		timerBar.progress = 0.0
		timerBar.progressTintColor = UIColor.yellowColor()
	}

	// MARK: - Recording

	func observeTimerInterval() {
		timerBar.progress += 0.1
		if timerBar.progress >= 0.5 {
			timerBar.progressTintColor = UIColor.greenColor()
		}

		if timerBar.progress >= 1.0 {
			stopRecording()
		}
	}

	@IBAction func startRecording() {
		vision.startVideoCapture()
		timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("observeTimerInterval"), userInfo: nil, repeats: true)
	}

	@IBAction func stopRecording() {
		vision.endVideoCapture()
		timer.invalidate()
	}

	// MARK: - PBJ Delegate

	private var videoUrl: NSURL?

	func vision(vision: PBJVision, capturedVideo videoDict: [NSObject : AnyObject]?, error: NSError?) {
		if let error = error {
			NSLog("Video Capture Error: \(error)")
		} else {
			if let out = videoDict?[PBJVisionVideoPathKey] as? String {
				host?.recordedSample(NSURL(fileURLWithPath: out))
			}
		}
	}

	// MARK: - Hosted

	var host: BakeRootController?

	override func didMoveToParentViewController(parent: UIViewController?) {
		host = parent as? BakeRootController
		if let host = host {
			resetTimerBar()
		} else {
			//moving out of parent
		}
	}
}
