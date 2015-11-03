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

		resetTimerBar()
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

	override func prefersStatusBarHidden() -> Bool {
		return true
	}

    // MARK: - Navigation
	@IBAction func torchControl(sender: UIButton) {
		performSegueWithIdentifier("Accept Sample Segue", sender: nil)
	}

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "Accept Sample Segue" {
			let acceptVC = segue.destinationViewController as! AcceptSampleController
			acceptVC.videoUrl = lastVideoUrl
			acceptVC.venues = venues
		}
    }

	@IBAction func segueFromAccepting(segue: UIStoryboardSegue) {
		resetTimerBar()
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

	// mark: PBJ Delegate

	private var lastVideoUrl: NSURL?

	func vision(vision: PBJVision, capturedVideo videoDict: [NSObject : AnyObject]?, error: NSError?) {
		if let error = error {
			NSLog("Video Capture Error: \(error)")
		} else {
			if let out = videoDict?[PBJVisionVideoPathKey] as? String {
				lastVideoUrl = NSURL(fileURLWithPath: out)
				performSegueWithIdentifier("Accept Sample Segue", sender: nil)
			}
			
		}
	}

}
