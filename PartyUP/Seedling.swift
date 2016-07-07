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

typealias SeedVenue = (id: String, loc: CLLocation, name: String)

func fetchSeedlings(atLocation location: CLLocation, inRadius radius: Int, complete: ([SeedVenue], NSError?)->Void) {
    if FBSDKAccessToken.currentAccessToken() != nil {
        FBSDKGraphRequest(graphPath: "/search", parameters: ["q":"club","type":"place","center":"\(location.coordinate.latitude),\(location.coordinate.longitude)","distance":"\(radius)","fields":"id,name,location"]).startWithCompletionHandler { (connection, places, error) in
            var venues = [SeedVenue]()
            if let places = places["data"] as? [AnyObject] where error == nil {
                for place in places {
                    guard let id = place["id"] as? String, let name = place["name"] as? String,
                    let here = place["location"] as? [String:AnyObject] else { continue }
                    guard let latitude = here["latitude"] as? Double,
                    let longitude = here["longitude"] as? Double else { continue }
                    let loc = CLLocation(latitude: latitude, longitude: longitude)
                    venues.append((id: id, loc: loc, name: name))
                }
            }
            complete(venues, error)
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
