//
//  AnimalTableCell.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-02-03.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//

import UIKit

class AnimalTableCell: UITableViewCell {
	@IBOutlet weak var cityLabel: UILabel!
	@IBOutlet weak var taglineLabel: UILabel!
	@IBOutlet weak var vitalityDot: UILabel!
	@IBOutlet weak var vitalityLabel: UILabel!

	var title = ""
	
	var locality: String? {
		didSet {
			let place = locality != nil ? locality! : NSLocalizedString("this hick town", comment: "Default city name in all venues cell")
			cityLabel?.text = title + place
		}
	}

	var venues: [Venue]? {
		willSet {
			NSNotificationCenter.defaultCenter().removeObserver(self)
		}
		didSet {
			if let venues = venues {
				let nc = NSNotificationCenter.defaultCenter()
                videoTotal = 0
				videoDate = nil
                venues.forEach { venue in
                    self.videoTotal += venue.vitality
                    self.videoDate = greaterDate(one: venue.samples?.first?.time, two: videoDate)
                    nc.addObserver(self, selector: Selector("updateVitality:"), name: Venue.VitalityUpdateNotification, object: venue)
                }
			}
			updateVitalityDisplay()
		}
	}
    
    private var videoTotal: Int = 0
    private var videoDate: NSDate?
    
    func updateVitality(note: NSNotification) {
        if let venue = note.object as? Venue, oldCount = note.userInfo?["old count"] as? Int {
            videoTotal += venue.vitality - oldCount
            videoDate = greaterDate(one: venue.samples?.first?.time, two: videoDate)
			updateVitalityDisplay()
        }
    }

    func updateVitalityDisplay() {
        var vitality = ""
        switch videoTotal {
        case 0:
            vitality = "🎈"
        case 1...5:
            vitality = "💃🏻"
        default:
            vitality = "🔥"
        }
        
        vitalityDot.text = vitality
        taglineLabel.text = NSLocalizedString("\(videoTotal) videos", comment: "All venues cell video count label")
        updateVitalityTime()
    }

	func updateVitalityTime() {
        if let time = videoDate {
            vitalityLabel.text = formatRelativeDateFrom(time, toDate: NSDate(), compact: true)
        } else {
            vitalityLabel.text = nil
        }
	}
}

private func greaterDate(one one: NSDate?, two: NSDate?) -> NSDate? {
    if let one = one {
        if let two = two {
            return one.compare(two) == .OrderedDescending ? one : two
        } else {
            return one
        }
    } else {
        return two
    }
}
