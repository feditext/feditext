// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import HTTP
import os

extension Publisher {
  func assignErrorsToAlertItem<Root: AnyObject>(
    to keyPath: ReferenceWritableKeyPath<Root, AlertItem?>,
    on object: Root,
    file: String = #fileID,
    line: Int = #line,
    function: String = #function
  ) -> AnyPublisher<Output, Never> {
    self.catch { [weak object] error -> Empty<Output, Never> in
      if let annotatedError = error as? AnnotatedError, annotatedError.failQuietly {
        os.Logger().error("Converting \(type(of: error), privacy: .public) error to quiet failure: \(error)")
      } else if let object = object {
        DispatchQueue.main.async {
          object[keyPath: keyPath] = AlertItem(
            error: error,
            file: file,
            line: line,
            function: function
          )
        }
      }

      return Empty()
    }
    .eraseToAnyPublisher()
  }
}
