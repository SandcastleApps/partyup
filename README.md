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

## Backend Service Requirements

PartyUP presents data from a number of backend services.  The secret keys for these services have been stripped from the source code.  You will be able to build and run PartyUP but it will not connect to the services.  It makes use of the following backend services:

* Amazon Web Services are used to store and distribute videos, votes and comments submitted through PartyUP.
* Google Places is used to find nearby venues relevant to PartyUP users (bars and other nightlife establishments).
* Facebook is used to verify user identity and collect seed images and videos submitted by nearby venues.

If you choose to fork and create your own application, you will have to adapt the application to use your own collection of services. The services currently required by PartyUP are described in the project wiki.

Would you like to contribute to PartyUP as distributed by Sandcastle? You will need some keys for the backend services to test your improvements. [Let us know](mail:todd@sandcastleapps.com) if you would like to contribute to Sandcastle's PartyUP distribution.  Instructions for setting up your development environment for building and testing PartyUP is available on the project wiki. 

## License

PartyUP has been open sourced under the [MIT license](License.md), enjoy!
