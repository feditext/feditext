// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import SwiftUI
import ViewModels

/// Edit the user's private note for an account.
public struct EditNoteView: View {
    @ObservedObject var accountViewModel: AccountViewModel
    @ObservedObject var noteViewModel: NoteViewModel

    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                editor
            }
        } else {
            NavigationView {
                editor
            }
        }
    }

    private var editor: some View {
        Form {
            TextEditor(text: $noteViewModel.note)
                .navigationTitle(
                    String.localizedStringWithFormat(
                        NSLocalizedString("account.note.for-%@", comment: ""),
                        accountViewModel.accountName
                    )
                )
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Label("dismiss", systemImage: "xmark.circle.fill")
                                .symbolRenderingMode(.hierarchical)
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.plain)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("account.note.save") {
                            accountViewModel.set(note: noteViewModel.note)
                            dismiss()
                        }
                    }
                }
        }
    }
}
