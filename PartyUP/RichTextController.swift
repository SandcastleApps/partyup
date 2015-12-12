//
//  RichTextController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-12-12.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit

class RichTextController: UIViewController {

	@IBOutlet weak var richText: UITextView! {
		didSet {
			if let url = url {
				do {
					try richText.attributedText = NSAttributedString(fileURL: url, options: [:], documentAttributes: nil)
				} catch {
					NSLog("Attributed Text Error: \(error)")
				}
			}
		}
	}

	var url: NSURL? {
		didSet {
			if let rich = richText, url = url {
				do {
					try rich.attributedText = NSAttributedString(fileURL: url, options: [:], documentAttributes: nil)
				} catch {
					NSLog("Attributed Text Error: \(error)")
				}
			}
		}
	}

}
