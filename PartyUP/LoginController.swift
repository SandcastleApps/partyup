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

    override func viewDidLoad() {
        super.viewDidLoad()

        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [UIColor(red: 251.0/255.0, green: 176.0/255.0, blue: 64.0/255.0, alpha: 1.0).CGColor, UIColor(red: 236.0/255.0, green: 0.0/255.0, blue: 140.0/255.0, alpha: 1.0).CGColor]
        view.layer.insertSublayer(gradient, atIndex: 0)
        view.layer.cornerRadius = 45.0
    }
}
