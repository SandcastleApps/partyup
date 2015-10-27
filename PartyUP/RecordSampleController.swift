//
//  RecordSampleController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-25.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit
import DACircularProgress
import CoreLocation

class RecordSampleController: UIViewController, VideoRecorderDelegate {

	@IBOutlet weak var recordButton: UIButton!
	@IBOutlet weak var timerBar: DACircularProgressView!
	
	var timer: NSTimer!
	var recordingController: VideoRecordController!
	var venues: [Venue]?
	var locationManager: CLLocationManager?

    override func viewDidLoad() {
        super.viewDidLoad()

		resetTimerBar()
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
			acceptVC.venues = venues
			acceptVC.locationManager = locationManager
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
		recordingController.start()
		timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("observeTimerInterval"), userInfo: nil, repeats: true)
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
			performSegueWithIdentifier("Accept Sample Segue", sender: nil)
		}
	}

	func videoRecorder(recorder: VideoRecordController, reportedInitializationError error: ErrorType) {
		recordButton.enabled = false
		UIAlertView(title: "Camera Unavailable", message: "\(error)", delegate: nil, cancelButtonTitle: "Rats!").show()
	}

}
