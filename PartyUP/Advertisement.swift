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
	enum Style: Int {
		case Page, Overlay
	}

	let administration: String
    let identifier: Int
    let feed: String
	let pages: [Int]
	let style: Style
	let media: String
    
	init(administration: String, identifier: Int, media: String, feed: String, pages: [Int], style: Style = .Page) {
        self.administration = administration
		self.identifier = identifier
		self.feed = feed
		self.pages = pages
		self.style = style
		self.media = media
    }
    
    var debugDescription: String {
        get { return "Administration = \(administration)\nIdentifier = \(identifier)\nFeed = \(feed)\nPages = \(pages)\nStyle = \(style)\nMedia = \(media)\n" }
    }
    
    //MARK - Internal Dynamo Representation
    
	internal convenience init(data: AdvertisementDB) {
        self.init(
            administration: data.administration! as String,
            identifier: data.identifier!.integerValue,
			media: (data.media as String?) ?? "unknown.html" ,
			feed: (data.feed as String?) ?? "",
			pages: /*data.pages.flatMap { $0.map { $0.integerValue } } ??*/ [],
			style: data.style.flatMap { Style(rawValue: $0.integerValue) } ?? .Page
        )
    }

    internal var dynamo: AdvertisementDB {
        get {
            let db = AdvertisementDB()
//            db.administration = administration
//            db.identifier = NSNumber(integer: identifier)
//            db.feed = feed
//			db.page = NSNumber(integer: page)
//            
            return db
        }
    }
    
    internal class AdvertisementDB: AWSDynamoDBObjectModel, AWSDynamoDBModeling
    {
        var administration: NSString?
        var identifier: NSNumber?
        var feed: NSString?
		var pages: [Int]?
		var style: NSNumber?
		var media: NSString?
        
        @objc static func dynamoDBTableName() -> String {
            return "Advertisements"
        }
        
        @objc static func hashKeyAttribute() -> String! {
            return "administration"
        }

		@objc static func rangeKeyAttribute() -> String! {
			return "identifier"
		}
    }
}

