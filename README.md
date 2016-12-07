# PartyUP

PartyUP is a lifestyle application developed by [Sandcastle Application Development Inc](http://www.sandcastleapps.com) that helps partiers make an informed decision about where to spend their night on the town.  It presents short videos that have been recently submitted by fellow partiers at nearby venues.  These videos convey the atmosphere at the venue right now.  This knowledge aids in venue selection and reduces Fear of Missing Out. To make the application immediately useful, content is also seeded from the Facebook pages of nearby venues.

Sandcastle is pleased to make the PartyUP iOS application available as open source.  You are free to fork the project, change the branding, and create your own product.  Alternatively, you can submit pull requests to this repository if you wish to see PartyUP, as distributed by Sandcastle, improve.

The [user manual](http://www.partyuptonight.com/v1/support.html) for PartyUP describes the usage scenarios for the product. The manual is a web site linked to by the PartyUP application, it has been made available as open source in the [partyuptonight](https://github.com/SandcastleApps/partyuptonight) repository.

## Platform and Tool Requirements

The PartyUP iOS application was written in Swift during the tumultuous early days of the language.  The tool and platform requirements as they currently stand are:

* Supports iOS 8 or higher
* Universal (iPhone and iPad)
* Implemented in Swift 2.3
* Built using Xcode 8
* Dependancies managed via Cocoapods 1.1

Given Swift 2.3 will not be supported for long, a migration to Swift 3 is a high priority for the project.

## Build Setup

The source code provided in the partyup repository has had the secret keys scrubbed out.  You can build and run the PartyUP but it will not be able to connect to the web services useful data. Whether you are collaborating on Sandcastle's distribution of PartyUP or working on your own fork, you will have to make keys available to Xcode.

The Xcode project gets service keys from environment variables. At Sandcastle we set these variables using [launchd](https://developer.apple.com/library/content/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html) on system startup using a launch agent.  A template launch agent plist has been provided at the root of the repository called com.sandcastle.partyup.plist.  The variables in this template are set to empty strings, you will need to populate them with appropriate keys and copy the file to ~/Library/LaunchAgents/. The following environment variables are used by Xcode when building PartyUP:  

* `PARTYUP_AWS_IDENTITY_POOL` - An identifier used to authenticate PartyUP with Amazon Web Services, allowing access to DynamoDB, S3, and Cognito. Source: [Amazon Web Services](https://aws.amazon.com)
* `PARTYUP_GOOGLE_PLACES_ID` - An identifier used to authenticate PartyUP with Google Places, allowing queries for nearby party venues. Source: [Google Developer Portal](https://developers.google.com/places/)
* `PARTYUP_FACEBOOK_APP_ID` - An identifier used to authenticate PartyUP with Facebook, allowing use of the login and graph APIs. Source: [Facebook Developer Portal](https://developers.facebook.com)
* `PARTYUP_APPLE_STORE_ID` - PartyUP encourages users to rate it on the AppStore using this identifier in the AppStore URL. Links to the AppStore appear in the acknowledgements screen and in the city hub footer.  Source: [iTunes Connect](https://itunesconnect.apple.com/)
* `PARTYUP_ENCRYPTION_EXPORT_COMPLIANCE` - PartyUP does not make use of custom encryption, but we signed up for an export compliance exemption from the US Government to cover our use of encryption in third party libraries.  This variable represents the identifier that Apple instructs you to put in your info.plist when you submit your government issued papers to them. Sources: [iTunes Connect](https://itunesconnect.apple.com/), [Instructions for getting ERN](http://iphonedevsdk.com/forum/business-legal-app-store/120048-apple-and-cryptographic-export-certification-steps-to-follow.html)
* `PARTYUP_FLURRY_APP_ID` - We track PartyUP usage using Flurry to improve the app and show it to be an opportunity as a marketing platform. Source: [Yahoo Developer Portal](https://developer.yahoo.com/analytics/)
* `PARTYUP_SURVEY_MONKEY_ID` - On the acknowlegements page we ask for feedback which is collected via Survey Monkey.  This variable identifies the survey. Source: [Survey Monkey](https://www.surveymonkey.com)
* `PARTYUP_DEVELOPMENT_TEAM_ID` - I tried to use an environment variable to set the Apple team identifier for PartyUP used for application provisioning.  Thus far, this variable does not work, you will have to go into the project settings and set your team identifier there, then be careful not to check it in. Source: [Apple Developer Portal](https://developer.apple.com) 

## PartyUP Backend Services

PartyUP makes use of backend services from Amazon, Google and Facebook to store and purvey videos from venues identified as likely nightlife spots. The secret keys for these services have been stripped from the source code. You will be able to build and run PartyUP but it will not connect to the services. This page describes how those services are used to aid those forking PartyUP in setting up those services.

### Google Places

Nearby venues are found using the Google Places REST API.  The unique venue identifiers assigned by Google are used to identify venues throughout PartyUP and venue names and locations come from Google Places.

### Amazon Web Services

Amazon Web Services are used to store and distribute the submissions, videos, votes, promotions, and advertising seen in PartyUP.  

#### DynamoDB Tables

DynamoDB is a NoSQL database that is used by partyUP to store and distribute information about video submissions, votes, and advertising.  The AWS iOS SDK is used in the application to access the tables and most records are mapped to Swift classes using the Dynamo Object Mapping classes.

##### Video Submissions

Video submissions (samples) are recorded in DynamoDB in the `Samples` table, fields include:

* `Event (string, hash key)`: the unique venue identifier retrieved from Google Places or the pattern `city$province$country` of the city in which the submission was made if no venue was specified.
* `Id (binary, range key)`: a base64 encoding of the submitting user's Cognito identifier UUID with a device specific submission count appended.
* `Timestamp (double)`: the time the video was submitted as seconds since January 1, 1970.
* `Up and Down (int)`:  the numbers of up and down votes the sample has gotten. Need to be handled atomically as multiple clients may be reading and writing it concurrently.
* `Comment (string, optional)`: an description provided by the user.
* `Prefix (string, nil by default)`: a lambda may move videos around in S3 to change thier longevity.  Nil in this field is interpreted as 'media'.

###### Votes and Offensive Video Reports

Each user's vote on a sample is recorded in the `Votes` DynamoDB table (accumulated votes are written to the `Samples` table as noted above).  Fields include:

* `Sample (binary, hash key)`: the identifier of the sample voted on, foreign key corresponding to the `Samples` table Id field.
* `User (binary, range key)`: a base64 encoding of the Incognito identifier UUID of the user submitting the vote.
* `Vote (int)`: the vote submitted by the user, 1 is up, -1 is down, 0 is meh.
* `Flag (bool)`: indicates whether the user reported the sample inappropriate.

###### Promotions

Promotions record venue specific information changing their display in city hub.  The Promotions DynamoDB table fields:

* `Venue (string, hash key)`: the venue unique identifier (supplied by Google Places) the promotion applies to.
* `City (string)`: the city of in which the venue resides, used by data entry folk, not PartyUP.
* `Name (string)`: the name of the venue, used by data entry folk, not PartyUP.
* `Placement (int)`: the relative placement of the venue in the city hub, higher numbers are better (they appear first in the city hub venue list). These need not be unique, the integer acts as a tier rather than an index.  The cells of venues promoted to a tier higher than 0 also get a colored background.
* `Tagline (string)`: a sting that will appear with the venue name in the venue's cell of the city hub.  Usually indicates special events or deals.

##### Advertising

The advertisements that appear in the video feed are represented by the `Advertisements` DynamoDB table.  The ads themselves are web pages stored on S3. Fields include:

* `Administration (string, hash key)`: identifies the area in which the advertisement has effect.  Has the pattern province$country.  PartyUP retrieve advertising only for area the user is in. 
* `Media (string, range key)`: the first character identifies a variation of the ad. The rest is the tail of the URL identifying the ad (loaded from Cloudfront).
* `Feeds (set of strings)`: indicate which city or venue video feeds an ad should appear in.  The first character identifies the type of feed (a - all feed, p - pregame, v - venue) and the remainder is a regex that must be matched for ads to appear in the feed.  Eg, `a:(Halifax|Sydney)` would have ads appear in the all feeds of Halifax or Sydney, but not Antigonish.
* `Pages (set of int)`: the pages of the video feeds identified by feeds on which the ad will appear.
* `Style (int)`: the display style of the ad, 0 puts the ad on it own page, 1 displays it as an overlay on a video page.

#### Simple Storage Service

An S3 bucket, `com.sandcastleapps.partyup`, is used to store submitted videos.  The videos are batched together with a few prefixes (media, favorites, and stick) that is reflected in the `Samples` table.  The name of the video file is generated from the submitter's Cognito identifier UUID with the submission count appended.  All videos should be set for reduced redundancy when submitted.

#### Cloudfront
Videos are distributed to PartyUP via streaming from Cloudfront.  The base URL for videos is `media.partyyuptonight.com`.  Advertising webpages are also served via Cloudfront at `media.partyuptonight.com/ads`.

#### Cognito

Cognito is used to authorize AWS access via both authenticated and unauthenticated access. Facebook login is used to authenticate users and provide authentication tokens to Cognito.  Authenticated users may take actions that change DynamoDB records (submit videos and vote) while unauthenticated users cannot take those actions.

### Facebook

User identity is authenticated using the Facebook Login API.  An authenticated user may opt to make a user name visible with submitted videos.  Logging in with Facebook also allows PartyUP to seed the venue feeds from supported venues with videos and pictures posted by the venue.  Authentication via Facebook is optional, though some PartyUP features are restricted to authenticated users.

### Flurry

Analytics for PartyUP are recorded via Flurry.  The Flurry iOS SDK is used to report user actions and errors. 

## Contributing to PartyUP

Would you like to contribute to PartyUP as distributed by Sandcastle? You will need some keys for the backend services to test your improvements. [Let us know](mail:todd@sandcastleapps.com) if you would like to contribute to Sandcastle's PartyUP distribution.

## License

PartyUP has been open sourced under the [MIT license](License.md), enjoy!
