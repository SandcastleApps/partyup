//
//  SampleAcceptingController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-10-02.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit
import AVFoundation

class SampleAcceptingController: UIViewController {

	var videoUrl: NSURL!

	@IBOutlet weak var commentField: UITextField!
	@IBOutlet weak var commentScroller: UIScrollView!

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
		if segue.identifier == "Acceptor Segue" {
			let viewerVC = segue.destinationViewController as! VideoViewController
			viewerVC.loop = true
			viewerVC.rate = 1.0
			viewerVC.player = AVPlayer(URL: videoUrl)
		} else if segue.identifier == "Accept Unwind" {
			//save sample and animate out
		} else if segue.identifier == "Reject Unwind" {
			//animate out
		}
    }

}
