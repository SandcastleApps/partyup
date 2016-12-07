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

## Backend Service Requirements

PartyUP presents data from a number of backend services.  The secret keys for these services have been stripped from the source code.  You will be able to build and run PartyUP but it will not connect to the services.  It makes use of the following backend services:

* Amazon Web Services are used to store and distribute videos, votes and comments submitted through PartyUP.
* Google Places is used to find nearby venues relevant to PartyUP users (bars and other nightlife establishments).
* Facebook is used to verify user identity and collect seed images and videos submitted by nearby venues.

If you choose to fork and create your own application, you will have to adapt the application to use your own collection of services. The services currently required by PartyUP are described in the project wiki.

Would you like to contribute to PartyUP as distributed by Sandcastle? You will need some keys for the backend services to test your improvements. [Let us know](mail:todd@sandcastleapps.com) if you would like to contribute to Sandcastle's PartyUP distribution.

## Developer Documentation

Descriptions of the backend services, development environment setup, and anything else development related are being put on the [PartyUP Developer](https://github.com/SandcastleApps/partyup/wiki) wiki.  

## License

PartyUP has been open sourced under the [MIT license](License.md), enjoy!
