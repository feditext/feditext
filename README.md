# Metatext / Feditext<sup>*</sup>

A free, open-source iOS Mastodon client.

<sup>*</sup>Feditext: this name is a placeholder. Suggestions are welcome. I don't know if it's an option to keep the Metatext name.

## Seeking Contributors

The upstream project [Metatext](https://github.com/metabolist/metatext) is seeking maintainers.
This fork is an attempt to build community to continue development.

If you are interested in joining the TestFlight group,
reach out to
[@bdube](https://gotgoat.com/@bdube)
or
[@vyr](https://demon.social/@vyr).

## Contributing Bug Reports

GitHub is used for bug tracking.
Search [existing issues](https://github.com/bdube/metatext) and create a new one if the issue is not yet tracked.
Upstream issues can be referenced in the [archived project](https://github.com/metabolist/metatext/issues).

## Contributing Translations

You can help translate Metatext on [CrowdIn](https://crowdin.com/project/metatext).

## Contributing Code

See the [contribution guidelines](https://github.com/metabolist/metatext/blob/main/CONTRIBUTING.md).

## Building

To build Metatext:

- Clone the repository (`git clone https://github.com/bdube/metatext.git`)
- Open `Feditext.xcodeproj` in Xcode
- Select the top-level "Feditext" item in Xcode and change the team in each target's "Signing & Capabilities" settings to your own

All dependencies are managed using [Swift Package Manager](https://swift.org/package-manager) and will automatically be installed by Xcode.

### Push Notifications

Push notifications will not work in development builds of Metatext unless you host your own instance of [metatext-apns](https://github.com/metabolist/metatext-apns) and change the `pushSubscriptionEndpointURL` constants in [IdentityService.swift](https://github.com/metabolist/metatext/blob/main/ServiceLayer/Sources/ServiceLayer/Services/IdentityService.swift) to its URL.

There is an issue to track this bdube/metatext#15.

## Architecture

- Metatext uses the [Model–view–viewmodel (MVVM) architectural pattern](https://en.wikipedia.org/wiki/Model–view–viewmodel).
- View models are clients of a service layer that abstracts network and local database logic.
- Different levels of the architecture are in different local Swift Packages. `import DB` and `import MastodonAPI` should generally only be done within the `ServiceLayer` package, and `import ServiceLayer` only within the `ViewModels` package.

## Acknowledgements

Metatext uses the following third-party libraries:

- [BlurHash](https://github.com/woltapp/blurhash)
- [CombineExpectations](https://github.com/groue/CombineExpectations)
- [GRDB](https://github.com/groue/GRDB.swift)
- [SDWebImage](https://github.com/SDWebImage/SDWebImage)
- [SQLCipher](https://github.com/sqlcipher/sqlcipher)
- [SwiftSoup](https://github.com/scinfu/SwiftSoup)

## Cryptography Notice

This distribution includes cryptographic software. The country in which you currently reside may have restrictions on the import, possession, use, and/or re-export to another country, of encryption software.
BEFORE using any encryption software, please check your country's laws, regulations and policies concerning the import, possession, or use, and re-export of encryption software, to see if this is permitted.
See <http://www.wassenaar.org/> for more information.

The U.S. Government Department of Commerce, Bureau of Industry and Security (BIS), has classified this software as Export Commodity Control Number (ECCN) 5D002.C.1, which includes information security software using or performing cryptographic functions with asymmetric algorithms.
The form and manner of this distribution makes it eligible for export under the License Exception ENC Technology Software Unrestricted (TSU) exception (see the BIS Export Administration Regulations, Section 740.13) for both object code and source code.

## License

Copyright (C) 2021 Metabolist

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <https://www.gnu.org/licenses/>.
