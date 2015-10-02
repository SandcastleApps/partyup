//
//  SampleBakingController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-25.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit

class SampleBakingController: UIViewController, VideoRecorderDelegate {

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

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "Recorder Segue" {
			if let recorderVC = segue.destinationViewController as? VideoRecordController {
				recordingController = recorderVC
				recordingController.delegate = self
			}
		}
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
			NSLog("Error Recording Video: \(error)")
		} else {
			let candidate = Sample(comment: "hello")
			try! NSFileManager.defaultManager().moveItemAtURL(target, toURL: NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(candidate.media.path!))
			SampleManager.defaultManager().submit(candidate, event: 1)
		}
	}

	func videoRecorder(recorder: VideoRecordController, reportedInitializationError error: ErrorType) {
		recordButton.enabled = false
		UIAlertView(title: "Camera Unavailable", message: "\(error)", delegate: nil, cancelButtonTitle: "Shit!").show()
	}

}
