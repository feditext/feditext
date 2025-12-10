// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation

/// Marker protocol: a low-level error annotated with our own metadata, usually HTTP-request-related.
public protocol AnnotatedError {
  /// If true, this is an error like a timeout or cancelled request that we can allow to fail without a user alert.
  var failQuietly: Bool { get }
}
