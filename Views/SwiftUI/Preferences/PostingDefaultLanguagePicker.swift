// Copyright © 2023 Vyr Cossont. All rights reserved.

import ServiceLayer
import SwiftUI

struct PostingDefaultLanguagePicker: View {
    @Binding var postingDefaultLanguage: PrefsLanguage.Tag?

    var body: some View {
        Picker("preferences.posting-default-language",
               selection: _postingDefaultLanguage) {
            Text("preferences.posting-default-language.not-set").tag(Optional<PrefsLanguage.Tag>.none)
            ForEach(PrefsLanguage.languageTagsAndNames(
                prefsLanguageTag: postingDefaultLanguage
            )) { prefsLanguage in
                Text(verbatim: prefsLanguage.localized).tag(Optional(prefsLanguage.id))
            }
        }
        .pickerStyle(.menu)
    }
}
