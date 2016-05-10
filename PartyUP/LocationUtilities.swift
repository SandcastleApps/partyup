//
//  LocationUtilities.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-05-10.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//

import SCLAlertView
import INTULocationManager

func alertFailureWithLocationServicesStatus(status: INTULocationStatus, dismissHandler dismiss: AlertHandler? = nil) -> SCLAlertViewResponder {
	var message = "Unknown Error"
	var hud = true

	switch status {
	case .ServicesRestricted:
		message = NSLocalizedString("Talk to your guardian about enabling location serices to submit of find nearby videos.", comment: "Location services restricted alert message")
		hud = false
	case .ServicesNotDetermined:
		fallthrough
	case .ServicesDenied:
		message = NSLocalizedString("Please enable \"While Using the App\" location access for PartyUP to submit or find nearby videos.", comment: "Location services denied alert message")
		hud = false
	case .ServicesDisabled:
		message = NSLocalizedString("Please enable location services to submit or find nearby videos.", comment: "Location services disabled alert message")
		hud = false
	case .TimedOut:
		message = NSLocalizedString("Timed out determining your location, try again later.", comment: "Location services timeout hud message.")
		hud = true
	case .Error:
		message = NSLocalizedString("An unknown location services error occured, sorry about that.", comment: "Location services unknown error hud message")
		hud = true
	case .Success:
		message = NSLocalizedString("Strange, very strange.", comment: "Location services succeeded but we went to error.")
		hud = true
	}

	var responder: SCLAlertViewResponder

	if hud == true {
		responder = alertFailureWithTitle(NSLocalizedString("Failed to find you", comment: "Location determination failure hud title"), andDetail: message, dismissHandler: dismiss)
	} else {
		let alert = SCLAlertView()
		if status != .ServicesRestricted {
			alert.addButton(NSLocalizedString("Settings", comment: "Goto settings app")) { UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!) }
		}
		responder = alert.showError(NSLocalizedString("Location Services", comment: "Location services unavailable alert title"),
		                            subTitle: message,
		                            closeButtonTitle: NSLocalizedString("Cancel", comment: "Default alert close."))
		if let dismiss = dismiss {
			responder.setDismissBlock(dismiss)
		}
	}

	return responder
}