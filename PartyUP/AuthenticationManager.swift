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

class AuthenticationManager {
	static let AuthenticationStatusChangeNotification = "AuthenticationStateChangeNotification"

	static let shared = AuthenticationManager()

	var authentics: [AuthenticationProvider] {
		return authenticators.map { $0 as AuthenticationProvider }
	}
	
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
    
    init() {
		authenticators = [FacebookAuthenticationProvider(keychain: keychain)]
    }

	func loginToProvider(provider: AuthenticationProvider, fromViewController controller: UIViewController) {
		if let provider = provider as? AuthenticationProviding {
			postTransitionToState(.Transitioning, withError: nil)
			provider.loginFromViewController(controller, completionHander: AuthenticationManager.reportLoggedInTokens(self))
		}
	}
    
    func logout() {
		authenticators.forEach{ $0.logout() }
        credentialsProvider?.logins = nil
        AWSCognito.defaultCognito().wipe()
        credentialsProvider?.clearKeychain()
		postTransitionToState(.Unauthenticated, withError: nil)
    }

	func reportLoggedInTokens(logins: [String:AnyObject]?, withError error: NSError?) {
		var task: AWSTask?

		if credentialsProvider == nil {
			task = self.initialize(logins)
		} else {
			var merged = credentialsProvider?.logins ?? [:]

			if let logins = logins {
				for (key, value) in logins {
					merged[key] = value
				}
				self.credentialsProvider?.logins = merged
			}
			task = self.credentialsProvider?.credentials()
		}

		task?.continueWithBlock { task in
			var state: AuthenticationState = .Unauthenticated
			if let logins = self.credentialsProvider?.logins where !logins.isEmpty { state = .Authenticated }
			self.postTransitionToState(state, withError: task.error)
			return nil
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

	private struct AwsConstants
	{
		static let RegionType = AWSRegionType.USEast1
		static let IdentityPool = "***REMOVED***"
	}
    
    private func resumeSession() {
        for auth in authenticators {
            if auth.wasLoggedIn {
				auth.resumeSessionWithCompletionHandler(AuthenticationManager.reportLoggedInTokens(self))
            }
        }
        
        if credentialsProvider == nil {
            reportLoggedInTokens(nil, withError: nil)
        }
    }
    
    private func initialize(logins: [String:AnyObject]?) -> AWSTask? {
        credentialsProvider = AWSCognitoCredentialsProvider(
            regionType: AwsConstants.RegionType,
            identityId: nil,
            identityPoolId: AwsConstants.IdentityPool,
			logins: logins)
        let configuration = AWSServiceConfiguration(
            region: AwsConstants.RegionType,
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