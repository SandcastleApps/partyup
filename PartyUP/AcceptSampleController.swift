//
//  AcceptSampleController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-10-02.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit
import AVFoundation

class AcceptSampleController: UIViewController {

	var videoUrl: NSURL!

	@IBOutlet weak var commentField: UITextField!

	override func prefersStatusBarHidden() -> Bool {
		return true
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)

		let nc = NSNotificationCenter.defaultCenter()

		nc.addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
		nc.addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
	}

	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)

		let nc = NSNotificationCenter.defaultCenter()

		nc.removeObserver(self, name: UIKeyboardDidShowNotification, object: nil)
		nc.removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
	}

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

	// MARK: - Keyboard

	@IBOutlet weak var distantBottom: NSLayoutConstraint!

	func keyboardWillShow(note: NSNotification) {
		if let kbSize = note.userInfo?[UIKeyboardFrameEndUserInfoKey]?.CGRectValue.size,
		kbAnimationDuration = note.userInfo?[UIKeyboardAnimationDurationUserInfoKey]?.doubleValue {
			distantBottom.constant = kbSize.height + 10
			UIView.animateWithDuration(kbAnimationDuration) { self.view.layoutIfNeeded() }
		}
	}

	func keyboardWillHide(note: NSNotification) {

		if let kbAnimationDuration = note.userInfo?[UIKeyboardAnimationDurationUserInfoKey]?.doubleValue {
			distantBottom.constant = 30
			UIView.animateWithDuration(kbAnimationDuration) { self.view.layoutIfNeeded() }
		}
	}

	@IBAction func editingEnded(sender: UITextField) {
		sender.resignFirstResponder()
	}

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "Reviewer Segue" {
			let viewerVC = segue.destinationViewController as! VideoViewController
			viewerVC.loop = true
			viewerVC.rate = 1.0
			viewerVC.player = AVPlayer(URL: videoUrl)
		} else if segue.identifier == "Accept Unwind" {
			do {
				let sample = Sample(comment: commentField.text)
				try NSFileManager.defaultManager().moveItemAtURL(videoUrl, toURL: NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(sample.media.path!))
				SampleManager.defaultManager().submit(sample, event: 1)
			} catch {
				NSLog("Failed to move accepted video: \(videoUrl) with error: \(error)")
			}

		} else if segue.identifier == "Reject Unwind" {
			do {
				try NSFileManager.defaultManager().removeItemAtURL(videoUrl)
			} catch {
				NSLog("Failed to delete rejected video: \(videoUrl) with error: \(error)")
			}
		}
    }

}