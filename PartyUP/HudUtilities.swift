//
//  HudUtilities.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-11-19.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import SCLAlertView

typealias AlertHandler = DismissBlock

func alertSuccessWithTitle(title: String, andDetail detail: String = String(), closeLabel close: String? = nil, dismissHandler dismiss: AlertHandler? = nil) {
	let duration = close == nil ? 2.5 : 0.0
	let alert = SCLAlertView()
	alert.showCloseButton = close != nil
	let responder = alert.showSuccess(title, subTitle: detail, closeButtonTitle: close, duration: duration)
	if let dismiss = dismiss {
		responder.setDismissBlock(dismiss)
	}
}

func alertFailureWithTitle(title: String, andDetail detail: String = String(), closeLabel close: String? = nil, dismissHandler dismiss: AlertHandler? = nil) {
	let duration = close == nil ? 4.0 : 0.0
	let alert = SCLAlertView()
	alert.showCloseButton = close != nil
	let responder = alert.showError(title, subTitle: detail, closeButtonTitle: close, duration: duration)
	if let dismiss = dismiss {
		responder.setDismissBlock(dismiss)
	}
}

func alertWaitWithTitle(title: String = NSLocalizedString("Working Hard", comment: "Please wait"), andDetail detail: String = String(), closeButton close: String? = NSLocalizedString("Cancel", comment: "Cancel button label"), dismissHandler dismiss: AlertHandler? = nil) -> SCLAlertViewResponder {
	let alert = SCLAlertView()
	alert.showCloseButton = close != nil
	let wait = alert.showWait(title, subTitle: detail, closeButtonTitle: close, colorStyle: 0xF45E63)
	if let dismiss = dismiss {
		wait.setDismissBlock(dismiss)
	}
	return wait
}