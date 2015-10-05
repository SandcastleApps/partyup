//
//  RecordSampleController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-25.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit

class RecordSampleController: UIViewController, VideoRecorderDelegate {

	@IBOutlet weak var recordButton: UIButton!
	@IBOutlet weak var timerBar: UIProgressView!

	var timer: NSTimer!

	var recordingController: VideoRecordController!

    override func viewDidLoad() {
        super.viewDidLoad()

		timerBar.transform = CGAffineTransformScale(timerBar.transform, 1.5, 1.75)
        timerBar.transform = CGAffineTransformRotate(timerBar.transform, CGFloat(3*M_PI/2))

		timer = NSTimer(timeInterval: 1.0, target: self, selector: Selector("observeTimerInterval"), userInfo: nil, repeats: true)
    }

	override func prefersStatusBarHidden() -> Bool {
		return true
	}

    // MARK: - Navigation
	@IBAction func torchControl(sender: UIButton) {
		performSegueWithIdentifier("Accept Sample Segue", sender: nil)
	}

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "Recorder Segue" {
			if let recorderVC = segue.destinationViewController as? VideoRecordController {
				recordingController = recorderVC
				recordingController.delegate = self
			}
		} else if segue.identifier == "Accept Sample Segue" {
			let acceptVC = segue.destinationViewController as! AcceptSampleController
			acceptVC.videoUrl = targetUrl
		}
    }

	@IBAction func segueFromAccepting(segue: UIStoryboardSegue) {
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
		recordingController.start()
		NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
	}

	@IBAction func stopRecording() {
		recordingController.stop()
		timer.invalidate()
	}

	// MARK: - Video Recorder Delegate

	var targetUrl = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("Recording.mp4")

	func videoRecorder(recorder: VideoRecordController, beganRecordingTo target: NSURL) {
		//do something
	}

	func videoRecorder(recorder: VideoRecordController, endedRecordingTo target: NSURL, withError error: ErrorType?) {
		if let error = error {
			UIAlertView(title: "Recording Error", message: "\(error)", delegate: nil, cancelButtonTitle: "Rats!").show()
		} else {
			performSegueWithIdentifier("Bake Accept Segue", sender: nil)
		}
	}

	func videoRecorder(recorder: VideoRecordController, reportedInitializationError error: ErrorType) {
		recordButton.enabled = false
		UIAlertView(title: "Camera Unavailable", message: "\(error)", delegate: nil, cancelButtonTitle: "Rats!").show()
	}

}
