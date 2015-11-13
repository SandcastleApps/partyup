//
//  CALayer+RuntimeProperties.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-11-12.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit
import QuartzCore

extension CALayer {
	var borderColorUI: UIColor? {
		get {
			if let color = borderColor {
				return UIColor(CGColor: color)
			} else {
				return nil
			}
		}
		set { borderColor = newValue?.CGColor } }
}
