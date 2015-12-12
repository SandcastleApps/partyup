//
//  HudUtilities.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-11-19.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import JGProgressHUD

func presentResultHud(hud: JGProgressHUD, inView view: UIView, withTitle title:  String, andDetail detail: String?, indicatingSuccess success: Bool) {
	if hud.hidden {
		hud.showInView(view, animated: false)
	}

	hud.indicatorView = success ? JGProgressHUDSuccessIndicatorView() : JGProgressHUDErrorIndicatorView()
	hud.textLabel.text = title
	hud.interactionType = .BlockAllTouches
	hud.detailTextLabel.text = detail
	hud.dismissAfterDelay(2.5, animated: true)
}