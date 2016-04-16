//
//  LoginController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-04-15.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import AWSCore

class LoginController: UIViewController, FBSDKLoginButtonDelegate {

	@IBOutlet weak var facebookButton: FBSDKLoginButton!
	
    override func viewDidLoad() {
        super.viewDidLoad()

        facebookButton.delegate = self
		facebookButton.readPermissions = ["public_profile", "email"]
    }

	// MARK: - Facebook Login

	func loginButtonWillLogin(loginButton: FBSDKLoginButton!) -> Bool {
		return true
	}

	func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
		if let error = error {
			let alert = UIAlertController(
				title: NSLocalizedString("Facebook Login Failed", comment: "Facebook login error title"),
				message: error.localizedDescription, preferredStyle: .Alert)
			presentViewController(alert, animated: true, completion: nil)
		} else if result.isCancelled {
			//handle cancelled
		} else {
			if let creds = AWSServiceManager.defaultServiceManager().defaultServiceConfiguration.credentialsProvider as? AWSCognitoCredentialsProvider {
				if result.token != nil {
					creds.logins[AWSCognitoLoginProviderKey.Facebook.rawValue] = result.token
				}
			}
		}
	}

	func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
		
	}
}
