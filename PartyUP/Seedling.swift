//
//  Seedling.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-07-02.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//

import Foundation
import FBSDKCoreKit
import CoreLocation
import SwiftDate

extension Venue {
    func fetchSeedlings() {
        if FBSDKAccessToken.currentAccessToken() != nil {
            FBSDKGraphRequest(graphPath: "/search", parameters: ["q":"\(self.name)","type":"place","center":"\(location.coordinate.latitude),\(location.coordinate.longitude)","distance":"\(10)","fields":"videos.limit(10){source,description,from,updated_time},photos.limit(10){source,description,from,updated_time}"]).startWithCompletionHandler { (connection, places, error) in
                var seeders = [Seedling]()
                if error == nil, let place = (places["data"] as? [AnyObject])?.first {
					for type in ["photos","videos"] {
						if let media = place[type] as? [String:AnyObject], let data = media["data"] as? [AnyObject] {
							for item in data {
								guard let source = (item["source"] as? String).flatMap({NSURL(string: $0)}),
								let time = (item["updated_time"] as? String).flatMap({$0.toDate(DateFormat.ISO8601)}) where time > 7.days.ago else { continue }
								let comment = item["description"] as? String
								let alias = (item["from"] as? [String:AnyObject])?["name"] as? String
								seeders.append(Seedling(user: NSUUID(), alias: alias, event: self, time: time, comment: comment, media: source))
							}
						}
					}
                }
                dispatch_async(dispatch_get_main_queue()) {
                    self.seeds = seeders
                }
            }
		} else {
			self.seeds = [Seedling]()
		}
    }
}

class Seedling: Tastable {
	let user: NSUUID
	let alias: String?
	unowned let event: Venue
	let time: NSDate
	let comment: String?
	let media: NSURL

	init(user: NSUUID, alias: String?, event: Venue, time: NSDate, comment: String?, media: NSURL) {
		self.user = user
		self.alias = alias
		self.event = event
		self.time = time
		self.comment = comment
		self.media = media
	}
}

