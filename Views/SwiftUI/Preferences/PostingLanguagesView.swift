// Copyright © 2023 Vyr Cossont. All rights reserved.

import ServiceLayer
import SwiftUI

/// Pick the languages that should appear in the post composition language selector.
struct PostingLanguagesView: View {
    @Binding var postingLanguages: Set<PrefsLanguage.Tag>

    var selectedLanguages: [PrefsLanguage] {
        Array(postingLanguages.map { PrefsLanguage(tag: $0) }.sorted())
    }

    var availableLanguages: [PrefsLanguage] {
        PrefsLanguage.languageTagsAndNames(prefsLanguageTag: nil)
            .filter { !postingLanguages.contains($0.tag) }
    }

    var body: some View {
        Form {
            Section("preferences.posting-languages.selected") {
                ForEach(selectedLanguages) { prefsLanguage in
                    HStack {
                        Button { () in
                            postingLanguages = postingLanguages.filter { $0 != prefsLanguage.tag }
                        } label: {
                            Label("preferences.posting-languages.remove", systemImage: "minus.circle.fill")
                                .labelStyle(.iconOnly)
                                .symbolRenderingMode(.multicolor)
                        }
                        Text(verbatim: prefsLanguage.localized)
                    }
                }
                .onDelete { indices in
                    let deletedTags = indices.map { selectedLanguages[$0].tag }
                    postingLanguages = postingLanguages.filter { !deletedTags.contains($0) }
                }
            }
            Section("preferences.posting-languages.available") {
                ForEach(availableLanguages) { prefsLanguage in
                    HStack {
                        Button { () in
                            $postingLanguages.wrappedValue = postingLanguages.union([prefsLanguage.tag])
                        } label: {
                            Label("preferences.posting-languages.add", systemImage: "plus.circle.fill")
                                .labelStyle(.iconOnly)
                                .symbolRenderingMode(.multicolor)
                        }
                        Text(verbatim: prefsLanguage.localized).tag(prefsLanguage.tag)
                    }
                }
            }
        }
    }
}

struct PostingLanguagesView_Previews: PreviewProvider {
    struct Container: View {
        @State var postingLanguages: Set<PrefsLanguage.Tag> = ["en", "zxx"]

        var body: some View {
            PostingLanguagesView(postingLanguages: $postingLanguages)
        }
    }

    static var previews: some View {
        Self.Container()
    }
}
