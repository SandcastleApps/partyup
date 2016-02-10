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
		taglineLabel.text = NSLocalizedString("\(videoTotal) videos", comment: "All venues cell video count label")
	}

	override func updateVitalityTime() {
		if let time = videoDate {
			vitalityLabel.text = formatRelativeDateFrom(time, toDate: NSDate(), compact: true)
		} else {
			vitalityLabel.text = nil
		}
	}
}


