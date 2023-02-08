// Copyright © 2023 Vyr Cossont. All rights reserved.

import ServiceLayer
import SwiftUI

/// Pick the default posting language.
struct PostingDefaultLanguageView: View {
    @Binding var postingDefaultLanguage: PrefsLanguage.Tag?

    /// We have to implement search ourselves instead of using `.searchable`
    /// because this view is not hosted in a `NavigationView`/`NavigationStack`.
    @State private var availableLanguageFilter: String = ""

    private var availableLanguages: [PrefsLanguage] {
        PrefsLanguage.languageTagsAndNames(prefsLanguageTag: postingDefaultLanguage)
            .filter { availableLanguageFilter.isEmpty || $0.localized.contains(availableLanguageFilter) }
    }

    var body: some View {
        Form {
            Section("preferences.posting-default-language") {
                HStack {
                    Label("preferences.posting-languages.available.filter", systemImage: "magnifyingglass")
                        .labelStyle(.iconOnly)
                    TextField("preferences.posting-languages.available.filter", text: $availableLanguageFilter)
                        .textFieldStyle(.roundedBorder)
                }
                Picker("preferences.posting-default-language",
                       selection: $postingDefaultLanguage) {
                    Text("preferences.posting-default-language.not-set").tag(Optional<PrefsLanguage.Tag>.none)
                    ForEach(availableLanguages) { prefsLanguage in
                        Text(verbatim: prefsLanguage.localized).tag(Optional(prefsLanguage.id))
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }
}

struct PostingDefaultLanguageView_Previews: PreviewProvider {
    struct Container: View {
        @State var postingDefaultLanguage: PrefsLanguage.Tag? = "en"

        var body: some View {
            PostingDefaultLanguageView(postingDefaultLanguage: $postingDefaultLanguage)
        }
    }

    static var previews: some View {
        Self.Container()
    }
}
