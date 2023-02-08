// Copyright © 2023 Vyr Cossont. All rights reserved.

import ServiceLayer
import SwiftUI

/// Pick the languages that should appear in the post composition language selector.
struct PostingLanguagesView: View {
    @Binding var postingLanguages: [PrefsLanguage.Tag]

    var selectedLanguages: [PrefsLanguage] {
        postingLanguages.map { PrefsLanguage(tag: $0) }
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
                            postingLanguages.removeAll { $0 == prefsLanguage.tag }
                        } label: {
                            Label("preferences.posting-languages.remove", systemImage: "minus.circle.fill")
                                .labelStyle(.iconOnly)
                                .symbolRenderingMode(.multicolor)
                        }
                        Text(verbatim: prefsLanguage.localized)
                        Spacer()
                        Image(systemName: "line.3.horizontal")
                    }
                }
                .onDelete { postingLanguages.remove(atOffsets: $0) }
                .onMove { postingLanguages.move(fromOffsets: $0, toOffset: $1) }
            }
            Section("preferences.posting-languages.available") {
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
