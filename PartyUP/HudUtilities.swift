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
	let alert = SCLAlertView().showSuccess(title, subTitle: detail, closeButtonTitle: close, duration: duration)
	if let dismiss = dismiss {
		alert.setDismissBlock(dismiss)
	}
}

func alertFailureWithTitle(title: String, andDetail detail: String = String(), closeLabel close: String? = nil, dismissHandler dismiss: AlertHandler? = nil) {
	let duration = close == nil ? 4.0 : 0.0
	let alert = SCLAlertView().showError(title, subTitle: detail, closeButtonTitle: close, duration: duration)
	if let dismiss = dismiss {
		alert.setDismissBlock(dismiss)
	}
}

func alertWaitWithTitle(title: String = NSLocalizedString("Working Hard", comment: "Please wait"), andDetail detail: String = String(), dismissHandler dismiss: AlertHandler? = nil) -> SCLAlertViewResponder {
	let alert = SCLAlertView()
	let wait = alert.showWait(title, subTitle: detail, closeButtonTitle: NSLocalizedString("Cancel", comment: "Cancel button label"), colorStyle: 0xF45E63)
	if let dismiss = dismiss {
		wait.setDismissBlock(dismiss)
	}
	return wait
}