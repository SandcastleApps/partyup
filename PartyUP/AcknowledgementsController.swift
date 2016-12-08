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

    @IBOutlet weak var loginButton: UIButton! {
        didSet {
            updateLogin()
        }
    }
    
	override func viewDidLoad() {
		super.viewDidLoad()

		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateLogin), name: AuthenticationManager.AuthenticationStatusChangeNotification, object: nil)
	}

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

    @IBAction func settings(sender: UIButton) {
        UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
    }
    
	@IBAction func recruit(sender: UIButton) {
        presentShareActionsOn(self, atOrigin: sender, withPrompt: NSLocalizedString("Share PartyUP", comment: "Share action prompt"))
	}

    @IBAction func pushThirdParty() {
        pushWebViewWithContent(NSBundle.mainBundle().URLForResource("Acknowledgments", withExtension: "rtf"), andTitle: NSLocalizedString("Third Party Libraries", comment: "Title of the Third Party Libraries webview"))
    }

	@IBAction func pushFeedback() {
		pushWebViewWithContent(PartyUpPaths.FeedbackUrl, andTitle: NSLocalizedString("Feedback", comment: "Title of the Feedback webview"))
    }
    
    @IBAction func ratePartyUp() {
        let url = "itms-apps://itunes.apple.com/app/id\(PartyUpKeys.AppleStoreIdentifier)"
        UIApplication.sharedApplication().openURL(NSURL(string: url)!)
    }
	
	@IBAction func pushSupport() {
		pushWebViewWithContent(PartyUpPaths.SupportUrl, andTitle: NSLocalizedString("Support", comment: "Title of the Support webview"))
	}

	@IBAction func pushTerms() {
		pushWebViewWithContent(PartyUpPaths.TermsUrl, andTitle: NSLocalizedString("Terms of Service", comment: "Title of the Terms webview"))
	}
    
    @IBAction func pushPrivacy() {
        pushWebViewWithContent(PartyUpPaths.PrivacyUrl, andTitle: NSLocalizedString("Privacy Policy", comment: "Title of the Privacy Policy webview"))
    }
    
	func updateLogin() {
        loginButton.setTitle(AuthenticationManager.shared.isLoggedIn ?
            NSLocalizedString("Logout", comment: "Logout button") :
            NSLocalizedString("Login", comment: "Login button"),
                             forState: .Normal)
    }
    
    @IBAction func authenticate(sender: UIButton) {
        let manager = AuthenticationManager.shared
        let flow = AuthenticationFlow.shared
        var message: String?
        var actions = [UIAlertAction]()
        
        if manager.isLoggedIn {
            let loggedin = manager.authentics.reduce(String()) { $0 + ($0.isEmpty ? "" : " + ") + $1.name }
            message = NSLocalizedString("Logout of \(loggedin)", comment: "Logout sheet message")
            actions.append(UIAlertAction(title: NSLocalizedString("Logout", comment: "Logout sheet action"),
            style: .Default) { _ in manager.logout() })
        } else {
            message = NSLocalizedString("Login using", comment: "Login sheet message")
            for auth in manager.authentics {
                actions.append(UIAlertAction(title: auth.name, style: .Default) { _ in flow.startOnController(self, withAuthenticator: auth) })
            }
        }
        
        actions.append(UIAlertAction(title: "Cancel", style: .Cancel) { _ in })
        
        let providers = UIAlertController(title: NSLocalizedString("Authentication", comment: "Authentication sheet title"),
                                          message: message,
                                          preferredStyle: .ActionSheet)
        
        actions.forEach { providers.addAction($0) }
        
        if let pop = providers.popoverPresentationController {
            pop.sourceView = sender
            pop.sourceRect = sender.bounds
        }
        
        self.presentViewController(providers, animated: true, completion: nil)
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
