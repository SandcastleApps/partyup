//
//  AnimalTableCell.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-02-03.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//

import UIKit

class AnimalTableCell: PartyTableCell {
	override func updateTagline() {
		taglineLabel.text = NSLocalizedString("\(videoTotal) posts", comment: "All venues cell post count label")
	}
}


