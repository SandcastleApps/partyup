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

	var recordingController: VideoRecordController!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

	@IBAction func startRecording(sender: UIButton) {
		recordingController.start()
	}

	@IBAction func stopRecording(sender: UIButton) {
		recordingController.stop()
	}

	// MARK: - Video Recorder Delegate

	var targetUrl = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("Recording.mp4")

	func beganRecording() {
		//do something
	}

	func endedRecording(error: ErrorType?) {
		if let error = error {
			NSLog("Error Recording Video: \(error)")
		} else {
			let candidate = Sample(comment: "hello")
			try! NSFileManager.defaultManager().moveItemAtURL(targetUrl, toURL: NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(candidate.media.path!))
			SampleManager.defaultManager().submit(candidate, event: 1)
		}
	}

	func deviceError(error: ErrorType) {
		recordButton.enabled = false
		UIAlertView(title: "Camera Unavailable", message: "\(error)", delegate: nil, cancelButtonTitle: "Shit!").show()
	}

}
