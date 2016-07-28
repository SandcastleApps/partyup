//
//  AuthenticationFlow.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-04-25.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//

import SCLAlertView

typealias AuthenticationFlowCompletion = (AuthenticationManager, Bool) -> Void

class AuthenticationFlow {

	private(set) var isFlowing = false
    
    func addAction(action: AuthenticationFlowCompletion) {
        completers.append(action)
    }
    
    func setPutoffs(putoffs: [String]) {
        self.putoffs = putoffs
    }
    
    func startOnController(controller: UIViewController) -> AuthenticationFlow {
        if !isFlowing {
            isFlowing = true
            beginOnController(controller)
        }
        return self
    }
    
    func stop() {
        if let leader = leader {
            leader.close()
            AuthenticationFlow.flow = nil
        }
    }

	private func beginOnController(controller: UIViewController) {
        let themeColor = UIColor(r: 247, g: 126, b: 86, alpha: 255)
        let alert = SCLAlertView(appearance: SCLAlertView.SCLAppearance(showCloseButton: false, shouldAutoDismiss: false))
        let inLabel = NSLocalizedString("Log in with", comment: "Login service button label")
        let outLabel = NSLocalizedString("Log out of", comment: "Logout service button label")
        for auth in manager.authentics {
            let label = "  " + (auth.isLoggedIn ? outLabel : inLabel) + " \(auth.name)"
            let button = alert.addButton(label, backgroundColor: auth.color) {
                [unowned alert] in alert.hideView()
                self.manager.loginToProvider(auth, fromViewController: controller)
            }
            button.setImage(auth.logo, forState: .Normal)
        }
        alert.addButton(NSLocalizedString("Read Terms of Service", comment: "Terms alert full terms action"), backgroundColor: themeColor) { UIApplication.sharedApplication().openURL(NSURL(string: "terms.html", relativeToURL: PartyUpConstants.PartyUpWebsite)!)
        }
        
        var off = putoffs.generate()
        if let putoff = off.next() {
            putoffButton = alert.addButton(putoff, backgroundColor: themeColor) { [weak self] in
                if let put = off.next() {
                    self?.putoffButton?.setTitle(put, forState: .Normal)
                } else {
					self?.end(true)
                }
            }
        }
        
        let file = NSBundle.mainBundle().pathForResource("Conduct", ofType: "txt")
        let message: String? = file.flatMap { try? String.init(contentsOfFile: $0) }
        leader = alert.showNotice(NSLocalizedString("Log in", comment: "Login Title"),
                                  subTitle: message!,
                                  colorStyle: 0xf77e56)
	}

	private func end(cancelled: Bool = false) {
        stop()
        self.completers.forEach { $0(self.manager, cancelled) }
	}

    init() {
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AuthenticationFlow.observeAuthenticationNotification(_:)), name: AuthenticationManager.AuthenticationStatusChangeNotification, object: manager)
	}

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

	@objc
	func observeAuthenticationNotification(note: NSNotification) {
		if let raw = note.userInfo?["new"] as? Int, let state = AuthenticationState(rawValue: raw) {
			switch state {
			case .Authenticated:
				alertSuccessWithTitle(NSLocalizedString("Logged In", comment: "Logged in alert title"),
				                                 andDetail: NSLocalizedString("Party Hearty!", comment: "Logged in alert detail"),
				                                 closeLabel: nil, dismissHandler: { self.end(false) })
			case .Unauthenticated:
				alertFailureWithTitle(NSLocalizedString("Not Logged In", comment: "Not logged in alert title"),
				                                 andDetail: NSLocalizedString("Better luck next time.", comment: "Not logged in alert detail"),
				                                 closeLabel: nil, dismissHandler: { self.end(false) })
			case .Transitioning:
				break
			}
		}
	}

	private let manager = AuthenticationManager.shared
	private var leader: SCLAlertViewResponder?
	private var completers = [AuthenticationFlowCompletion]()
    private var putoffs = [NSLocalizedString("Let me think about it", comment: "Login putoff")]
    private var putoffButton: SCLButton?

    static var shared: AuthenticationFlow {
        flow = flow ?? AuthenticationFlow()
		return flow!
	}

	private static var flow: AuthenticationFlow?
}
