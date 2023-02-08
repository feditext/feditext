// Copyright © 2023 Vyr Cossont. All rights reserved.

import ServiceLayer
import SwiftUI

/// Pick the languages that should appear in the post composition language selector.
struct PostingLanguagesView: View {
    @Binding var postingLanguages: [PrefsLanguage.Tag]

    /// We have to implement search ourselves instead of using `.searchable`
    /// because this view is not hosted in a `NavigationView`/`NavigationStack`.
    @State private var availableLanguageFilter: String = ""

    private var selectedLanguages: [PrefsLanguage] {
        postingLanguages.map { PrefsLanguage(tag: $0) }
    }

    private var availableLanguages: [PrefsLanguage] {
        PrefsLanguage.languageTagsAndNames(prefsLanguageTag: nil)
            .filter {
                !postingLanguages.contains($0.tag)
                && (availableLanguageFilter.isEmpty || $0.localized.contains(availableLanguageFilter))
            }
    }

    var body: some View {
        Form {
            Section("preferences.posting-languages.selected") {
                ForEach(selectedLanguages) { prefsLanguage in
                    HStack {
                        Button { () in
                            postingLanguages.removeAll { $0 == prefsLanguage.tag }
                        } label: {
                            Label("preferences.posting-languages.remove", systemImage: "minus.circle.fill")
                                .labelStyle(.iconOnly)
                                .symbolRenderingMode(.multicolor)
                        }
                        Text(verbatim: prefsLanguage.localized)
                        Spacer()
                        Label("preferences.posting-languages.move", systemImage: "line.3.horizontal")
                            .labelStyle(.iconOnly)
                    }
                }
                .onDelete { postingLanguages.remove(atOffsets: $0) }
                .onMove { postingLanguages.move(fromOffsets: $0, toOffset: $1) }
            }
            Section("preferences.posting-languages.available") {
                HStack {
                    Label("preferences.posting-languages.available.filter", systemImage: "magnifyingglass")
                        .labelStyle(.iconOnly)
                    TextField("preferences.posting-languages.available.filter", text: $availableLanguageFilter)
                        .textFieldStyle(.roundedBorder)
                }
                ForEach(availableLanguages) { prefsLanguage in
                    HStack {
                        Button { () in
                            postingLanguages.append(prefsLanguage.tag)
                        } label: {
                            Label("preferences.posting-languages.add", systemImage: "plus.circle.fill")
                                .labelStyle(.iconOnly)
                                .symbolRenderingMode(.multicolor)
                        }
                        Text(verbatim: prefsLanguage.localized)
                    }
                }
            }
        }
    }
}

struct PostingLanguagesView_Previews: PreviewProvider {
    struct Container: View {
        @State var postingLanguages: [PrefsLanguage.Tag] = ["en", "zxx"]

        var body: some View {
            PostingLanguagesView(postingLanguages: $postingLanguages)
        }
    }

    static var previews: some View {
        Self.Container()
    }
}
