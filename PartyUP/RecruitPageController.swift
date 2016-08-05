//
//  RecruitPageController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-12-04.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit

class RecruitPageController: UIViewController, PageProtocol {

	var page: Int!
	var ad: NSURL?
    
    @IBOutlet weak var loginLabel: UILabel! {
        didSet {
            updateLoginPrompt()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(RecruitPageController.updateLoginPrompt), name: AuthenticationManager.AuthenticationStatusChangeNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		navigationController?.navigationBar.topItem?.title = NSLocalizedString("Share", comment: "Recruitment page navigation title")
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if let avc = segue.destinationViewController as? AdvertisingOverlayController {
			avc.url = ad
		}
	}
    
    @objc private func updateLoginPrompt() {
        if !AuthenticationManager.shared.isLoggedIn {
            loginLabel.text = NSLocalizedString("Login to see Facebook posts from venues!", comment: "Login prompt - not logged in")
        } else {
            loginLabel.text = NSLocalizedString("Post a video or share PartyUP with friends!", comment: "Login prompt - logged in")
        }
    }
}
