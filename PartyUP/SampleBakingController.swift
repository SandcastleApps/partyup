//
//  SampleBakingController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-25.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit

class SampleBakingController: UIViewController, VideoRecorderDelegate {

	let candidate = Sample(comment: nil)

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
				recorderVC.delegate = self
			}
		}
    }

	// MARK: - Video Recorder Delegate

	var targetUrl: NSURL { get { return NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(candidate.media.path!)} }

	func beganRecording() {
		//do something
	}

	func endedRecording(error: ErrorType?) {
		if let error = error {
			NSLog("Error Recording Video: \(error)")
		} else {
			SampleManager.defaultManager().submit(candidate, event: 1)
		}
	}

	func deviceError(error: ErrorType) {
		NSLog("Error Setting Recording Device: \(error)")
	}

}
