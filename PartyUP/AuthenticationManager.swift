//
//  AuthenticationManager.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-04-17.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//

import Foundation
import KeychainAccess
import AWSCore
import AWSCognito

enum AuthenticationState: Int {
	case Unauthenticated, Transitioning, Authenticated
}

class AuthenticationManager: NSObject, AWSIdentityProviderManager {
	static let AuthenticationStatusChangeNotification = "AuthenticationStateChangeNotification"

	static let shared = AuthenticationManager()

	var authentics: [AuthenticationProvider] {
		return authenticators.map { $0 as AuthenticationProvider }
	}
	
    let user = User()
    
    var identity: NSUUID? {
		if let identity = credentialsProvider?.identityId {
			return NSUUID(UUIDString: identity[identity.endIndex.advancedBy(-36)..<identity.endIndex])
		} else {
			return nil
		}
	}
    
    var isLoggedIn: Bool {
        return authenticators.reduce(false) { return $0 || $1.isLoggedIn }
    }

	private(set) var state: AuthenticationState = .Transitioning
    
    
    override init() {
		authenticators = [FacebookAuthenticationProvider(keychain: keychain)]
		super.init()
    }

	func loginToProvider(provider: AuthenticationProvider, fromViewController controller: UIViewController) {
		if let provider = provider as? AuthenticationProviding {
			postTransitionToState(.Transitioning, withError: nil)
			provider.loginFromViewController(controller, completionHander: AuthenticationManager.reportLoginWithError(self))
		}
	}
    
    func logout() {
		authenticators.forEach{ $0.logout() }
        AWSCognito.defaultCognito().wipe()
        credentialsProvider?.clearKeychain()
		reportLoginWithError(nil)
    }

	func reportLoginWithError(error: NSError?) {
		var task: AWSTask?

		if credentialsProvider == nil {
			task = self.initialize()
		} else {
			credentialsProvider?.invalidateCachedTemporaryCredentials()
            credentialsProvider?.identityProvider.clear()
			task = credentialsProvider?.getIdentityId()
		}

		task?.continueWithBlock { task in
			var state: AuthenticationState = .Unauthenticated
			if self.isLoggedIn { state = .Authenticated }
			self.postTransitionToState(state, withError: task.error)
			return nil
		}
	}
    
    // MARK: - Identity Provider Manager
    
    func logins() -> AWSTask {
		let tasks = authenticators.map { $0.token() }

		return AWSTask(forCompletionOfAllTasksWithResults: tasks).continueWithSuccessBlock { task in
			if let tokens = task.result as? [String] {
				var logins = [String:String]()
				for authentic in zip(self.authenticators,tokens) {
					logins[authentic.0.identityProviderName] = authentic.1
				}
				return logins
			} else {
				return nil
			}
		}
    }

	// MARK: - Application Delegate Integration

	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		let isHandled = authenticators.reduce(false) { $0 || $1.application(application, didFinishLaunchingWithOptions: launchOptions) }
		resumeSession()
		return isHandled
	}

	func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
		return authenticators.reduce(false) { $0 || $1.application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation) }
	}

	// MARK: - Private

	private let keychain = Keychain(service: NSBundle.mainBundle().bundleIdentifier!)
	private var authenticators = [AuthenticationProviding]()
	private var credentialsProvider: AWSCognitoCredentialsProvider?
    
    private func resumeSession() {
        for auth in authenticators {
            if auth.wasLoggedIn {
				auth.resumeSessionWithCompletionHandler(AuthenticationManager.reportLoginWithError(self))
            }
        }
        
        if credentialsProvider == nil {
            reportLoginWithError(nil)
        }
    }
    
    private func initialize() -> AWSTask? {
        credentialsProvider = AWSCognitoCredentialsProvider(
            regionType: PartyUpKeys.AwsRegionType,
            identityPoolId: PartyUpKeys.AwsIdentityPool,
			identityProviderManager: self)
        let configuration = AWSServiceConfiguration(
            region: PartyUpKeys.AwsRegionType,
            credentialsProvider: credentialsProvider)
        
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
        
        return self.credentialsProvider?.getIdentityId()
    }

	private func postTransitionToState(state: AuthenticationState, withError error: NSError?) {
		let old = self.state
		self.state = state
		dispatch_async(dispatch_get_main_queue()) {
			let notify = NSNotificationCenter.defaultCenter()
			var info: [String:AnyObject] = ["old" : old.rawValue, "new" : state.rawValue]
			if error != nil { info["error"] = error }
			notify.postNotificationName(AuthenticationManager.AuthenticationStatusChangeNotification, object: self, userInfo: info)
		}
	}
}
