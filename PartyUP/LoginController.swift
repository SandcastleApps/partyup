//
//  LoginController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-04-15.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//

import UIKit

class LoginController: UIViewController {
    lazy var conduct: String? = {
        let file = NSBundle.mainBundle().pathForResource("Conduct", ofType: "txt")
        return file.flatMap { try? String.init(contentsOfFile: $0) }
    }()

	private let gradient: CAGradientLayer = {
		let gradient = CAGradientLayer()
		gradient.colors = [UIColor(red: 251.0/255.0, green: 176.0/255.0, blue: 64.0/255.0, alpha: 1.0).CGColor, UIColor(red: 236.0/255.0, green: 0.0/255.0, blue: 140.0/255.0, alpha: 1.0).CGColor]
		return gradient
	}()

    override func viewDidLoad() {
        super.viewDidLoad()

		gradient.frame = view.frame
		view.layer.masksToBounds = true
        view.layer.insertSublayer(gradient, atIndex: 0)
        view.layer.cornerRadius = 10.0

		setPopinTransitionStyle(.SpringyZoom)
		setPopinOptions([.DisableAutoDismiss, .DimmingViewStyleNone])
		setPopinAlignment(.Centered)

		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateLogin(_:)), name: AuthenticationManager.AuthenticationStatusChangeNotification, object: nil)
	}

	override func willMoveToParentViewController(parent: UIViewController?) {
		if let parent = parent {
			setPreferedPopinContentSize(CGSize(width: parent.view.bounds.width - 35.0, height: parent.view.bounds.height - 80.0))
		}
	}

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

	@IBAction func loginWithFacebook(sender: UIButton) {
		let manager = AuthenticationManager.shared
		manager.loginToProvider(manager.authentics.first!, fromViewController: self)
	}
	
	@IBOutlet weak var conductLabel: UILabel! {
		didSet {
			conductLabel.text = conduct
		}
	}

	func updateLogin(note: NSNotification) {
		if let state = note.userInfo?["new"] as? Int where AuthenticationState(rawValue: state) == .Authenticated {
			dismiss()
		}
	}

	@IBAction func dismiss() {
		presentingPopinViewController().dismissCurrentPopinControllerAnimated(true)
	}
}
