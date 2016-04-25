//
//  UIColor+Uint.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-04-24.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//

import UIKit

extension UIColor {
	convenience init(r: UInt, g: UInt, b: UInt, alpha: UInt) {
		self.init(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: CGFloat(alpha)/255.0)
	}
}