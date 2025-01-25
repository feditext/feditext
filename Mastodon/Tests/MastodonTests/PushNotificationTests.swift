// Copyright © 2024 Vyr Cossont. All rights reserved.

@testable import Mastodon
import XCTest

final class PushNotificationTests: XCTestCase {
    /// Test that we can parse a push notification with an integer ID.
    func testParseIntID() throws {
        let json = """
            {
                "access_token": "ACCESS_TOKEN",
                "body": "this is my post",
                "title": "some account posted",
                "icon": "https://example.test/icon.png",
                "notification_id": 123,
                "notification_type": "status",
                "preferred_locale": "en-US"
            }
            """
        let pushNotification = try MastodonDecoder().decode(PushNotification.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(pushNotification.notificationId, "123")
    }
  
    /// Test that we can parse a push notification with a string ID.
    func testParseStringID() throws {
        let json = """
            {
                "access_token": "ACCESS_TOKEN",
                "body": "this is my post",
                "title": "some account posted",
                "icon": "https://example.test/icon.png",
                "notification_id": "ABC",
                "notification_type": "status",
                "preferred_locale": "en-US"
            }
            """
        let pushNotification = try MastodonDecoder().decode(PushNotification.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(pushNotification.notificationId, "ABC")
    }
}
