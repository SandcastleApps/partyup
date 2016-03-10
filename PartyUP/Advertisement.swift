//
//  Advertisement.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-01-12.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//

import AWSDynamoDB

final class Advertisement: CustomDebugStringConvertible
{
    static var ads = [Advertisement]()
    
	enum Style: Int {
		case Page, Overlay
	}
    
    enum FeedCategory: String {
        case All = "a", Pregame = "p", Venue = "v"
    }
    
    typealias FeedMask = [FeedCategory:String]

	let administration: String
    let feeds: FeedMask
	let pages: [Int]
	let style: Style
	let media: String
    
    init(administration: String, media: String, feeds: FeedMask, pages: [Int], style: Style = .Page) {
        self.administration = administration
		self.feeds = feeds
		self.pages = pages
		self.style = style
		self.media = media
    }
    
    var debugDescription: String {
        get { return "Administration = \(administration)\nFeeds = \(feeds)\nPages = \(pages)\nStyle = \(style)\nMedia = \(media)\n" }
    }
    
    //MARK - Internal Dynamo Representation
    
	internal convenience init(data: AdvertisementDB) {
        var feeder = FeedMask(minimumCapacity: 3)
        if let feeds = data.feeds as? [String] {
            for filter in feeds {
                if let category = FeedCategory(rawValue: filter[filter.startIndex..<filter.startIndex.advancedBy(1)]) {
                    feeder[category] = filter[filter.startIndex.advancedBy(2)..<filter.endIndex]
                }
            }
        }
        
        self.init(
            administration: data.administration! as String,
			media: data.media as! String,
            feeds: feeder,
			pages: data.pages.flatMap { $0.map { $0.integerValue } } ?? [],
			style: data.style.flatMap { Style(rawValue: $0.integerValue) } ?? .Page
        )
    }

    internal var dynamo: AdvertisementDB {
        get {
            let db = AdvertisementDB()
            db.administration = administration
            db.feeds = feeds.map { $0.0.rawValue + ":" + $0.1 }
            db.pages = pages.map { NSNumber(integer: $0) }
            db.style = NSNumber(integer: style.rawValue)
            db.media = media
            
            return db
        }
    }
    
    internal class AdvertisementDB: AWSDynamoDBObjectModel, AWSDynamoDBModeling
    {
        var administration: NSString?
        var identifier: NSNumber?
        var feeds: [NSString]?
		var pages: [NSNumber]?
		var style: NSNumber?
		var media: NSString?
        
        @objc static func dynamoDBTableName() -> String {
            return "Advertisements"
        }
        
        @objc static func hashKeyAttribute() -> String! {
            return "administration"
        }

		@objc static func rangeKeyAttribute() -> String! {
			return "media"
		}
    }
}

