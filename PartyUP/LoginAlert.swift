//
//  LoginAlert.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-04-25.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//

import SCLAlertView

func alertLoginForController(controller: UIViewController, withDismiss dismiss: AlertHandler) {
    let manager = AuthenticationManager.shared
    let terms = SCLAlertView()
    let face = terms.addButton("  Log in with Facebook") { manager.loginToProvider(manager.authentics.first!, fromViewController: controller) }
    let fbIcon = UIImage(named: "Facebook")
    face.setImage(fbIcon, forState: .Normal)
    terms.addButton(NSLocalizedString("Read Terms of Service", comment: "Terms alert full terms action")) { UIApplication.sharedApplication().openURL(NSURL(string: "terms.html", relativeToURL: PartyUpConstants.PartyUpWebsite)!)
    }
    
    terms.shouldAutoDismiss = false
    
    let file = NSBundle.mainBundle().pathForResource("Conduct", ofType: "txt")
    let message: String? = file.flatMap { try? String.init(contentsOfFile: $0) }
    terms.showNotice(NSLocalizedString("Log in", comment: "Login Title"),
                     subTitle: message!,
                     closeButtonTitle: NSLocalizedString("Let me think about it", comment: "Login putoff"),
                     colorStyle: 0xf77e56).setDismissBlock(dismiss)
    
    face.backgroundColor = UIColor(r: 59, g: 89, b: 152, alpha: 255)
}
