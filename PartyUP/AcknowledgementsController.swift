//
//  AcknowledgementsController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-12-03.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit

class AcknowledgementsController: UITableViewController {
    @IBOutlet weak var versionLabel: UILabel! {
        didSet {
            let bundle = NSBundle.mainBundle()
            let version = bundle.objectForInfoDictionaryKey("CFBundleShortVersionString") as? String ?? "?.?"
            let build = bundle.objectForInfoDictionaryKey("CFBundleVersion") as? String ?? "?"
            versionLabel.text = "v\(version)(\(build))"
        }
    }

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

	}

	@IBAction func recruit(sender: UIButton) {
        presentShareActionsOn(self, atOrigin: sender, withPrompt: NSLocalizedString("Share PartyUP", comment: "Share action prompt"))
	}

    @IBAction func pushThirdParty() {
        pushWebViewWithContent(NSBundle.mainBundle().URLForResource("Acknowledgments", withExtension: "rtf"), andTitle: NSLocalizedString("Third Party Libraries", comment: "Title of the Third Party Libraries webview"))
    }

	@IBAction func pushFeedback() {
		pushWebViewWithContent(NSURL(string: "https://www.surveymonkey.com/r/***REMOVED***"), andTitle: NSLocalizedString("Feedback", comment: "Title of the Feedback webview"))
    }
    
    @IBAction func ratePartyUp() {
        let url = "itms-apps://itunes.apple.com/app/id\(PartyUpConstants.AppleStoreIdentifier)"
        UIApplication.sharedApplication().openURL(NSURL(string: url)!)
    }
	
	@IBAction func pushSupport() {
		pushWebViewWithContent(NSURL(string: "support.html", relativeToURL: PartyUpConstants.PartyUpWebsite), andTitle: NSLocalizedString("Support", comment: "Title of the Support webview"))
	}

	@IBAction func pushTerms() {
		pushWebViewWithContent(NSURL(string: "terms.html", relativeToURL: PartyUpConstants.PartyUpWebsite), andTitle: NSLocalizedString("Terms of Service", comment: "Title of the Terms webview"))
	}
    
    @IBAction func pushPrivacy() {
        pushWebViewWithContent(NSURL(string: "privacy.html", relativeToURL: PartyUpConstants.PartyUpWebsite), andTitle: NSLocalizedString("Privacy Policy", comment: "Title of the Privacy Policy webview"))
    }
    
    private func pushWebViewWithContent(content: NSURL?, andTitle title: String) {
        if let webVC = storyboard?.instantiateViewControllerWithIdentifier("Web Controller") as? WebPageController {
            webVC.url = content
            webVC.purpose = title
            navigationController?.pushViewController(webVC, animated: true)
        }
    }

	@IBAction func segueFromThirdParty(segue: UIStoryboardSegue) {

	}
}
