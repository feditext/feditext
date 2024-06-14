# Feditext

A free, open-source iOS client for [Mastodon](https://joinmastodon.org/), [Glitch](https://glitch-soc.github.io/docs/), [GotoSocial](https://gotosocial.org/), [Firefish](https://joinfirefish.org/), [Akkoma](https://akkoma.social/), and other Mastodon-API-compatible Fediverse instance servers.

Feditext is based on the [Metatext](https://github.com/metabolist/metatext) project, which has concluded and is no longer maintained. Feditext is updated with Mastodon 4 features and better support for non-Mastodon instances.

## Testers Wanted

If you are interested in joining the TestFlight group, please DM our official Fedi account [@Feditext@mastodon.social](https://mastodon.social/@Feditext), and follow it for announcements and release notes.

## Contributing Bug Reports

GitHub is used for bug tracking.
Search [existing issues](https://github.com/feditext/feditext/issues) and create a new one if the issue is not yet tracked.
Upstream issues can be referenced in the [archived project](https://github.com/metabolist/metatext/issues).

## Contributing Translations

Existing translations for Metatext are in a [CrowdIn](https://crowdin.com/project/metatext) project.
Translation contributions will be welcome again after some more
project infrastructure is in place for Feditext.

## Contributing Code

See the [contribution guidelines](CONTRIBUTING.md).

## Building

To build Feditext:

- Clone the repository (`git clone https://github.com/feditext/feditext.git`)
- Run `git update-index --skip-worktree Identity.xcconfig` to ignore changes to the ID file so you don't commit them
- Change the development team ID and bundle ID base in [`Identity.xcconfig`](Identity.xcconfig) to your own

All dependencies are managed using [Swift Package Manager](https://swift.org/package-manager) and will automatically be installed by Xcode.

### Push Notifications

Push notifications will not work in development builds of Feditext unless you host your own instance of [feditext-apns](https://github.com/feditext/feditext-apns) and change the `pushSubscriptionEndpointURL` constants in [`IdentityService.swift`](ServiceLayer/Sources/ServiceLayer/Services/IdentityService.swift) to its URL.

There is an issue to track this: feditext/feditext#15.

## Architecture

- Feditext uses the [Model–view–viewmodel (MVVM) architectural pattern](https://en.wikipedia.org/wiki/Model–view–viewmodel).
- View models are clients of a service layer that abstracts network and local database logic.
- Different levels of the architecture are in different local Swift Packages. `import DB` and `import MastodonAPI` should generally only be done within the `ServiceLayer` package, and `import ServiceLayer` only within the `ViewModels` package.

## Acknowledgements

Feditext uses the following third-party libraries:

- [BlurHash](https://github.com/woltapp/blurhash)
- [CombineExpectations](https://github.com/groue/CombineExpectations)
- [GRDB](https://github.com/groue/GRDB.swift)
- [SDWebImage](https://github.com/SDWebImage/SDWebImage)
- [SQLCipher](https://github.com/sqlcipher/sqlcipher)
- [SwiftSoup](https://github.com/scinfu/SwiftSoup)
- [Semver](https://github.com/ddddxxx/Semver)

Feditext uses the following third-party artwork:

- Feditext "ft" logos by Robert George [@rrgeorge](https://raphus.social/@rrgeorge) ([CC-BY 4.0](https://creativecommons.org/licenses/by/4.0/))
- ActivityPub logo by mray from [activitypub.rocks](https://activitypub.rocks/) ([CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/))

Feditext is maintained by:

- [@vyr](https://demon.social/@vyr)
- [@bdube](https://gotgoat.com/@bdube)

And of course, we wouldn't be here without [Metabolist](https://metabolist.org/)'s incredible work on the original Metatext project.

## Cryptography Notice

This distribution includes cryptographic software. The country in which you currently reside may have restrictions on the import, possession, use, and/or re-export to another country, of encryption software.
BEFORE using any encryption software, please check your country's laws, regulations and policies concerning the import, possession, or use, and re-export of encryption software, to see if this is permitted.
See <http://www.wassenaar.org/> for more information.

The U.S. Government Department of Commerce, Bureau of Industry and Security (BIS), has classified this software as Export Commodity Control Number (ECCN) 5D002.C.1, which includes information security software using or performing cryptographic functions with asymmetric algorithms.
The form and manner of this distribution makes it eligible for export under the License Exception ENC Technology Software Unrestricted (TSU) exception (see the BIS Export Administration Regulations, Section 740.13) for both object code and source code.

## License

Copyright © 2022–2021 Metabolist
Copyright © 2022–2023 Brian Dube, Vyr Cossont

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <https://www.gnu.org/licenses/>.
