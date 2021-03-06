//
//  Keys.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-11-02.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//

import Foundation
import AWSCore


struct PartyUpKeys {
    static let AppleStoreIdentifier = NSBundle.mainBundle().objectForInfoDictionaryKey("AppleStoreID") as! String
    static let FlurryIdentifier = NSBundle.mainBundle().objectForInfoDictionaryKey("FlurryAppID") as! String
    static let AwsRegionType = AWSRegionType.USEast1
    static let AwsIdentityPool = NSBundle.mainBundle().objectForInfoDictionaryKey("AwsIdentityPool") as! String
    static let GooglePlaces = NSBundle.mainBundle().objectForInfoDictionaryKey("GooglePlacesID") as! String
    static let SurveyMonkey = NSBundle.mainBundle().objectForInfoDictionaryKey("SurveyMonkeyID") as! String
}

struct PartyUpPaths {
    static let StorageBucket = "com.sandcastleapps.partyup"
    static let WebsiteUrl = NSURL(scheme: "http", host: "www.partyuptonight.com/v1", path: "/")!
    static let SupportUrl = NSURL(string: "support.html", relativeToURL: WebsiteUrl)
    static let TermsUrl = NSURL(string: "terms.html", relativeToURL: WebsiteUrl)
    static let PrivacyUrl = NSURL(string: "privacy.html", relativeToURL: WebsiteUrl)
    static let ContentRootUrl = NSURL(scheme: "http", host: "media.partyuptonight.com", path: "/")!
    static let AdvertisementUrl = NSURL(string: "ads/", relativeToURL: ContentRootUrl)
    static let FeedbackUrl = NSURL(scheme: "https", host: "www.surveymonkey.com", path: "/r/\(PartyUpKeys.SurveyMonkey)")!
}
