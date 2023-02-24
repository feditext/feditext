// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation

/// Trivial view model for a note on an account.
public class NoteViewModel: ObservableObject {
    @Published public var note: String

    public init(note: String) {
        self.note = note
    }
}
