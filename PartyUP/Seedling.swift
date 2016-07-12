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

//typealias SeedVenue = (id: String, loc: CLLocation, name: String)
//
//func fetchSeedlings(atLocation location: CLLocation, inRadius radius: Int, complete: ([SeedVenue], NSError?)->Void) {
//    if FBSDKAccessToken.currentAccessToken() != nil {
//        FBSDKGraphRequest(graphPath: "/search", parameters: ["q":"","type":"place","center":"\(location.coordinate.latitude),\(location.coordinate.longitude)","distance":"\(radius)","fields":"id,name,location"]).startWithCompletionHandler { (connection, places, error) in
//            var venues = [SeedVenue]()
//            if let places = places["data"] as? [AnyObject] where error == nil {
//                for place in places {
//                    guard let id = place["id"] as? String, let name = place["name"] as? String,
//                    let here = place["location"] as? [String:AnyObject] else { continue }
//                    guard let latitude = here["latitude"] as? Double,
//                    let longitude = here["longitude"] as? Double else { continue }
//                    let loc = CLLocation(latitude: latitude, longitude: longitude)
//                    venues.append((id: id, loc: loc, name: name))
//                }
//            }
//            complete(venues, error)
//        }
//    }
//}

extension Venue {
    func fetchSeedlings() {
        if FBSDKAccessToken.currentAccessToken() != nil {
            FBSDKGraphRequest(graphPath: "/search", parameters: ["q":"\(self.name)","type":"place","center":"\(location.coordinate.latitude),\(location.coordinate.longitude)","distance":"\(10)","fields":"videos.limit(5){source,description,from,updated_time},photos.limit(5){source,description,from,updated_time}"]).startWithCompletionHandler { (connection, places, error) in
                var seeders = [Seedling]()
                if error == nil, let place = (places["data"] as? [AnyObject])?.first {
                    if let photos = place["photos"] as? [String:AnyObject], let data = photos["data"] as? [AnyObject] {
                        for photo in data {
                            guard let source = (photo["source"] as? String).flatMap({NSURL(string: $0)}) else { continue }
                            let comment = photo["description"] as? String
                            let alias = (photo["from"] as? [String:AnyObject])?["name"] as? String
                            let time = photo["updated_time"]
                            seeders.append(Seedling(user: NSUUID(), alias: alias, event: self, time: NSDate(), comment: comment, media: source))
                        }
                    }
                }
                dispatch_async(dispatch_get_main_queue()) {
                    self.seeds = seeders
                }
            }
        }
    }
}

//func fetchSeedlings(withQuery query: String, atLocation location: CLLocation, inRadius radius: Int) {
//	if FBSDKAccessToken.currentAccessToken() != nil {
//		FBSDKGraphRequest(graphPath: "/search", parameters: ["q":"","type":"place","center":"\(location.coordinate.latitude),\(location.coordinate.longitude)","distance":"\(radius)","fields":"id,name,location"]).startWithCompletionHandler { (connection, places, error) in
//			print("** for ** \(query)")
//			if let places = places["data"] as? [AnyObject] where error == nil {
//
//				for place in places {
//					guard let id = place["id"] as? String, let name = place["name"] as? String,
//						let here = place["location"] as? [String:AnyObject] else { continue }
//					guard let latitude = here["latitude"] as? Double,
//						let longitude = here["longitude"] as? Double else { continue }
//					print("-> \(id) \(name) (\(latitude),\(longitude))")
//				}
//			}
//		}
//	}
//}

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

