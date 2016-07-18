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
            FBSDKGraphRequest(graphPath: "/search", parameters: ["q":"\(self.name)","type":"place","center":"\(location.coordinate.latitude),\(location.coordinate.longitude)","distance":"\(100)","fields":"link"]).startWithCompletionHandler { (connection, places, error) in
				if error == nil,
					let place = (places["data"] as? [AnyObject])?.first as? [String:AnyObject],
					let id = place["id"] as? String {
					FBSDKGraphRequest(graphPath: "/\(id)", parameters: ["fields":"video_broadcasts{video{source,description,from,updated_time}}"]).startWithCompletionHandler {
						(connection, page, error) in
						var seeders = [Seedling]()
						if let broadcasts = page["video_broadcasts"] as? [String:AnyObject], let videos = broadcasts["data"] as? [AnyObject] {
							for video in videos {
								if let item = video["video"] as? [String:AnyObject]{
								guard let source = (item["source"] as? String).flatMap({NSURL(string: $0)}),
									let time = (item["updated_time"] as? String).flatMap({$0.toDate(DateFormat.ISO8601)})  else { continue }
								let comment = item["description"] as? String
								let alias = (item["from"] as? [String:AnyObject])?["name"] as? String
								seeders.append(Seedling(user: NSUUID(), alias: alias, event: self, time: time, comment: comment, media: source, via: "Facebook"))
							}
							}
						}

						dispatch_async(dispatch_get_main_queue()) {
							self.seeds = seeders
						}
					}
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
    let via: String

    init(user: NSUUID, alias: String?, event: Venue, time: NSDate, comment: String?, media: NSURL, via: String = "Facebook") {
		self.user = user
		self.alias = alias
		self.event = event
		self.time = time
		self.comment = comment
		self.media = media
        self.via = via
	}
}

