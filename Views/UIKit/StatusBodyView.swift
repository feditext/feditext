// Copyright © 2020 Metabolist. All rights reserved.

import AppUrls
import Combine
import Foundation
import Mastodon
import UIKit
import ViewModels

/// Show a post's text and attachments only.
/// ``StatusView`` uses this to display the post with user info.
final class StatusBodyView: UIView {
    let spoilerTextLabel = AnimatedAttachmentLabel()
    let toggleShowContentButton = CapsuleButton()
    let contentTextView = TouchFallthroughTextView()
    let attachmentsView = AttachmentsView()
    let tagsView = TouchFallthroughTextView()
    // TODO: (Vyr) quote posts: replace with mini status view for quoted statuses
    private var quotedButtonConfiguration = UIButton.Configuration.plain()
    let quotedView = UIButton()
    let pollView = PollView()
    let cardView = CardView()

    typealias TagPair = (id: TagViewModel.ID, name: String)
    private var tagViewTagPairs = [TagPair]()

    private var cancellables = Set<AnyCancellable>()

    /// Show this many lines of a folded post as a preview.
    static let numLinesFoldedPreview: Int = 2

    // /// Don't fold hashtags when there are this many or fewer, and they follow post text without an intervening newline.
    // TODO: (Vyr) implement this: https://github.com/feditext/feditext/issues/305

    var viewModel: StatusViewModel? {
        didSet {
            guard let viewModel = viewModel else { return }

            let foldTrailingHashtags = viewModel.identityContext.appPreferences.foldTrailingHashtags
            let outOfTextTagPairs = findOutOfTextTagPairs()

            let mutableContent = NSMutableAttributedString(
                attributedString: viewModel.content.nsFormatSiren(contentTextStyle)
            )
            let trailingTagPairs: [(id: TagViewModel.ID, name: String)]
            if foldTrailingHashtags {
                trailingTagPairs = Self.dropTrailingHashtags(mutableContent)
            } else {
                trailingTagPairs = []
            }
            let mutableSpoilerText = NSMutableAttributedString(string: viewModel.spoilerText)
            let mutableSpoilerFont = UIFont.preferredFont(forTextStyle: contentTextStyle).bold()
            let contentFont = UIFont.preferredFont(forTextStyle: isContextParent ? .title3 : .callout)
            let contentRange = NSRange(location: 0, length: mutableContent.length)

            contentTextView.shouldFallthrough = !isContextParent

            mutableContent.addAttribute(.foregroundColor, value: UIColor.label, range: contentRange)
            mutableContent.insert(emojis: viewModel.contentEmojis,
                                  view: contentTextView,
                                  identityContext: viewModel.identityContext)
            mutableContent.resizeAttachments(toLineHeight: contentFont.lineHeight)
            contentTextView.attributedText = mutableContent
            contentTextView.accessibilityLanguage = viewModel.language
            contentTextView.isHidden = contentTextView.text.isEmpty

            if viewModel.hasSpoiler {
                mutableSpoilerText.insert(emojis: viewModel.contentEmojis,
                                          view: spoilerTextLabel,
                                          identityContext: viewModel.identityContext)
                mutableSpoilerText.resizeAttachments(toLineHeight: spoilerTextLabel.font.lineHeight)
            }
            spoilerTextLabel.font = mutableSpoilerFont
            spoilerTextLabel.attributedText = mutableSpoilerText
            spoilerTextLabel.accessibilityLanguage = viewModel.language
            spoilerTextLabel.isHidden = !viewModel.hasSpoiler

            toggleShowContentButton.setTitle(
                viewModel.shouldShowContent
                    ? NSLocalizedString("status.show-less", comment: "")
                    : NSLocalizedString("status.show-more", comment: ""),
                for: .normal)
            toggleShowContentButton.isHidden = (!viewModel.hasSpoiler
                    || viewModel.alwaysExpandSpoilers
                    || !viewModel.shouldShowContentWarningButton)
                && !viewModel.shouldHideDueToLongContent
            toggleShowContentButton.setContentCompressionResistancePriority(.required, for: .vertical)
            toggleShowContentButton.setContentHuggingPriority(.required, for: .vertical)

            let hideContent = viewModel.shouldHideDueToSpoiler && !viewModel.shouldShowContent
            contentTextView.isHidden = hideContent
            contentTextView.textContainer.lineBreakMode = .byTruncatingTail
            contentTextView.textContainer.maximumNumberOfLines = viewModel.shouldShowContentPreview
                ? Self.numLinesFoldedPreview
                : 0
            contentTextView.accessibilityLanguage = viewModel.language

            tagViewTagPairs = trailingTagPairs + outOfTextTagPairs
            tagsView.isHidden = hideContent
                || (!foldTrailingHashtags && outOfTextTagPairs.isEmpty)
                || tagViewTagPairs.isEmpty
            // Get the text in there now even if it's not styled right.
            // Otherwise sometimes the view's height is wrong.
            updateTagView()
            tagsView.accessibilityValue = NSLocalizedString("search.scope.tags", comment: "")
            tagsView.accessibilityLanguage = viewModel.language
            tagsView.accessibilityTraits = .staticText
            tagsView.accessibilityHint = NSLocalizedString("status.accessibility.go-to-hashtags-hint", comment: "")

            var accessibilityCustomActions = [UIAccessibilityCustomAction]()

            if let quotedViewModel = viewModel.quoted {
                quotedView.isHidden = false
                let actionName: String
                if let domain = quotedViewModel.sharingURL?.host {
                    quotedView.accessibilityLabel = String.localizedStringWithFormat(
                        NSLocalizedString("status.quote.quoted-post-on-%@", comment: ""),
                        domain
                    )
                    actionName = String.localizedStringWithFormat(
                        NSLocalizedString("status.quote.go-to-quoted-post-on-%@", comment: ""),
                        domain
                    )
                } else {
                    quotedView.accessibilityLabel = NSLocalizedString("status.quote.quoted-post", comment: "")
                    actionName = NSLocalizedString("status.quote.go-to-quoted-post", comment: "")
                }
                quotedButtonConfiguration.title = quotedViewModel.sharingURL?.absoluteString
                quotedView.configuration = quotedButtonConfiguration

                accessibilityCustomActions.append(.init(name: actionName) { [weak self] _ in
                    guard let quoted = self?.viewModel?.quoted else { return false }

                    quoted.presentDisplayStatus()
                    return true
                })
            } else {
                quotedView.isHidden = true
            }

            attachmentsView.isHidden = viewModel.attachmentViewModels.isEmpty
            attachmentsView.viewModel = viewModel

            pollView.isHidden = viewModel.pollOptions.isEmpty || !viewModel.shouldShowContent
            pollView.viewModel = viewModel
            pollView.isAccessibilityElement = !isContextParent || viewModel.hasVotedInPoll || viewModel.isPollExpired

            cardView.viewModel = viewModel.cardViewModel
            cardView.isHidden = viewModel.cardViewModel == nil || !viewModel.shouldShowContent

            accessibilityAttributedLabel = accessibilityAttributedLabel(forceShowContent: false)

            mutableContent.enumerateAttribute(
                .link,
                in: NSRange(location: 0, length: mutableContent.length),
                options: []) { attribute, range, _ in
                guard let url = attribute as? URL else { return }

                accessibilityCustomActions.append(
                    UIAccessibilityCustomAction(
                        name: String.localizedStringWithFormat(
                            NSLocalizedString("accessibility.activate-link-%@", comment: ""),
                            mutableContent.attributedSubstring(from: range).string)) { [weak self] _ in
                        guard let contentTextView = self?.contentTextView else { return false }

                        _ = contentTextView.delegate?.textView?(
                            contentTextView,
                            shouldInteractWith: url,
                            in: range,
                            interaction: .invokeDefaultAction)

                        return true
                    })
            }

            self.accessibilityCustomActions = accessibilityCustomActions
                + (tagsView.accessibilityCustomActions ?? [])
                + attachmentsView.attachmentViewAccessibilityCustomActions
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        initialSetup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        updateTagView()
    }
}

extension StatusBodyView {
    static func estimatedHeight(width: CGFloat,
                                identityContext: IdentityContext,
                                status: Status,
                                configuration: CollectionItem.StatusConfiguration) -> CGFloat {
        let plainTextContent = String(status.displayStatus.content.attrStr.characters)

        let contentFont = UIFont.preferredFont(forTextStyle: configuration.isContextParent ? .title3 : .callout)
        var height: CGFloat = 0

        var contentHeight = plainTextContent.height(
            width: width,
            font: contentFont)

        if status.displayStatus.card != nil {
            contentHeight += .compactSpacing
            contentHeight += CardView.estimatedHeight(
                width: width,
                identityContext: identityContext,
                status: status,
                configuration: configuration)
        }

        if status.displayStatus.poll != nil {
            contentHeight += .defaultSpacing
            contentHeight += PollView.estimatedHeight(
                width: width,
                identityContext: identityContext,
                status: status,
                configuration: configuration
            )
        }

        //  This would be so much more convenient if it took a StatusViewModel…
        //  For now, it duplicates a lot of code from non-static contexts in this class and from StatusViewModel.
        let hasSpoiler = !status.displayStatus.spoilerText.isEmpty
        let alwaysExpandSpoilers = identityContext.identity.preferences.readingExpandSpoilers
        let shouldHideDueToSpoiler = hasSpoiler && !alwaysExpandSpoilers

        let hasLongContent: Bool
        if plainTextContent.count > StatusViewModel.foldCharacterLimit {
            hasLongContent = true
        } else {
            let newlineCount = plainTextContent.prefix(StatusViewModel.foldCharacterLimit).filter { $0.isNewline }.count
            hasLongContent = newlineCount > StatusViewModel.foldNewlineLimit
        }
        let shouldHideDueToLongContent = hasLongContent && identityContext.appPreferences.foldLongPosts

        let shouldShowContent = configuration.showContentToggled
            || !(shouldHideDueToSpoiler || shouldHideDueToLongContent)

        if hasSpoiler {
            // Include spoiler text height.
            height += status.displayStatus.spoilerText.height(width: width, font: contentFont)
            height += .compactSpacing
        }

        if shouldHideDueToSpoiler || shouldHideDueToLongContent {
            // Include Show More button height.
            height += NSLocalizedString("status.show-more", comment: "").height(
                width: width,
                font: .preferredFont(forTextStyle: .headline))
            height += .compactSpacing
        }

        if shouldShowContent {
            // Include full height of content.
            height += contentHeight
        } else if !configuration.showContentToggled && !hasSpoiler && shouldHideDueToLongContent {
            // Include first few lines of content.
            height += contentFont.lineHeight * CGFloat(Self.numLinesFoldedPreview)
        }

        if !status.displayStatus.mediaAttachments.isEmpty {
            height += .compactSpacing
            height += AttachmentsView.estimatedHeight(
                width: width,
                identityContext: identityContext,
                status: status,
                configuration: configuration)
        }

        return height
    }

    func accessibilityAttributedLabel(forceShowContent: Bool) -> NSAttributedString {
        let accessibilityAttributedLabel = NSMutableAttributedString(string: "")

        if !spoilerTextLabel.isHidden,
           let spoilerText = spoilerTextLabel.attributedText,
           let viewModel = viewModel,
           !viewModel.shouldShowContent,
           !forceShowContent {
            accessibilityAttributedLabel.appendWithSeparator(
                NSLocalizedString("status.content-warning.accessibility", comment: ""))

            let mutableSpoilerText = NSMutableAttributedString(attributedString: spoilerText)
            if let language = viewModel.language {
                mutableSpoilerText.addAttribute(
                    .accessibilitySpeechLanguage,
                    value: language as NSString,
                    range: .init(location: 0, length: mutableSpoilerText.length)
                )
            }
            accessibilityAttributedLabel.appendWithSeparator(mutableSpoilerText)
        } else if !contentTextView.isHidden || forceShowContent,
                  let content = contentTextView.attributedText {
            let mutableContent = NSMutableAttributedString(attributedString: content)
            if let language = viewModel?.language {
                mutableContent.addAttribute(
                    .accessibilitySpeechLanguage,
                    value: language as NSString,
                    range: .init(location: 0, length: mutableContent.length)
                )
            }
            accessibilityAttributedLabel.append(mutableContent)
        }

        for view in [tagsView, quotedView, attachmentsView, pollView, cardView] where !view.isHidden {
            guard let viewAccessibilityAttributedLabel = view.accessibilityAttributedLabel else { continue }

            accessibilityAttributedLabel.appendWithSeparator(viewAccessibilityAttributedLabel)
        }

        return accessibilityAttributedLabel
    }
}

extension StatusBodyView: UITextViewDelegate {
    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction) -> Bool {
        switch interaction {
        case .invokeDefaultAction:
            viewModel?.urlSelected(URL)
            return false
        case .preview: return false
        case .presentActions: return false
        @unknown default: return false
        }
    }
}

private extension StatusBodyView {
    func initialSetup() {
        let stackView = UIStackView()

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = .defaultSpacing

        spoilerTextLabel.numberOfLines = 0
        spoilerTextLabel.adjustsFontForContentSizeCategory = true
        stackView.addArrangedSubview(spoilerTextLabel)

        toggleShowContentButton.addAction(
            UIAction { [weak self] _ in self?.viewModel?.toggleShowContent() },
            for: .touchUpInside)
        stackView.addArrangedSubview(toggleShowContentButton)

        contentTextView.adjustsFontForContentSizeCategory = true
        contentTextView.backgroundColor = .clear
        contentTextView.delegate = self
        stackView.addArrangedSubview(contentTextView)

        tagsView.adjustsFontForContentSizeCategory = true
        tagsView.backgroundColor = .clear
        tagsView.delegate = self
        tagsView.linkTextAttributes.removeValue(forKey: .foregroundColor)
        tagsView.linkTextAttributes.removeValue(forKey: .underlineStyle)
        stackView.addArrangedSubview(tagsView)

        // TODO: (Vyr) quote posts: replace with mini status view
        stackView.addArrangedSubview(quotedView)
        quotedView.accessibilityHint = NSLocalizedString("status.quote.goes-to-quoted-post-hint", comment: "")
        quotedButtonConfiguration.buttonSize = .large
        quotedButtonConfiguration.titleLineBreakMode = .byTruncatingTail
        quotedButtonConfiguration.imagePadding = .defaultSpacing
        quotedButtonConfiguration.image = .init(systemName: "text.quote")
        quotedView.configuration = quotedButtonConfiguration
        quotedView.addAction(
            UIAction { [weak self] _ in
                self?.viewModel?.quoted?.presentDisplayStatus()
            },
            for: .primaryActionTriggered
        )

        stackView.addArrangedSubview(attachmentsView)

        stackView.addArrangedSubview(pollView)

        cardView.button.addAction(
            UIAction { [weak self] _ in
                guard
                    let viewModel = self?.viewModel,
                    let url = viewModel.cardViewModel?.url
                else { return }

                viewModel.urlSelected(url)
            },
            for: .touchUpInside)
        stackView.addArrangedSubview(cardView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    var isContextParent: Bool {
        viewModel?.configuration.isContextParent ?? false
    }

    var contentTextStyle: UIFont.TextStyle {
        isContextParent ? .title3 : .callout
    }

    // TODO: (Vyr) this stuff needs to be moved to StatusViewModel

    /// Find any hashtags that are attached to the status but don't appear in the text.
    /// Return their IDs and display text.
    func findOutOfTextTagPairs() -> [TagPair] {
        guard let viewModel = viewModel else { return [] }
        let tagViewModels = viewModel.tagViewModels
        let content = viewModel.content

        var tagIds = Set(tagViewModels.map { $0.id })
        for (tagId, _) in content.runs[\.hashtag] {
            guard let tagId = tagId else { continue }
            tagIds.remove(tagId)
        }

        return tagViewModels
            .filter { tagIds.contains($0.id) }
            .map { ($0.id, $0.name) }
    }

    /// Drop trailing hashtags from the string.
    /// Return a list of the tag IDs that were dropped and the original text for each.
    static func dropTrailingHashtags(_ mutableContent: NSMutableAttributedString) -> [TagPair] {
        var tagIds = Set<TagViewModel.ID>()
        var tagPairs = [(TagViewModel.ID, String)]()
        var startOfTrailingHashtags: String.Index = mutableContent.string.endIndex

        let entireString = NSRange(location: 0, length: mutableContent.length)
        mutableContent.enumerateAttribute(
            HTML.Key.hashtag,
            in: entireString,
            options: .reverse
        ) { val, nsRange, stop in
            guard let range = Range(nsRange, in: mutableContent.string) else {
                assertionFailure("Couldn't create range for substring")
                stop.pointee = true
                return
            }
            let substring = mutableContent.string[range]

            if let tagId = val as? TagViewModel.ID {
                startOfTrailingHashtags = range.lowerBound
                let (firstSeen, _) = tagIds.insert(tagId)
                if firstSeen {
                    tagPairs.append((tagId, String(substring)))
                }
            } else {
                // Go back through the substring while there is trailing whitespace.
                var i = substring.endIndex
                while i > substring.startIndex {
                    let prevI = substring.index(before: i)
                    if !substring[prevI].isWhitespace {
                        break
                    }
                    i = prevI
                }
                startOfTrailingHashtags = i
                if i > substring.startIndex {
                    // Contains non-hashtag, non-whitespace text. Stop here.
                    stop.pointee = true
                }
            }
        }

        guard startOfTrailingHashtags < mutableContent.string.endIndex else { return tagPairs }

        mutableContent.deleteCharacters(
            in: NSRange(
                startOfTrailingHashtags..<mutableContent.string.endIndex,
                in: mutableContent.string
            )
        )

        return tagPairs.reversed()
    }

    /// Update the tag view when the tag list, the user's list of followed tags, or the accessibility contrast changes.
    func updateTagView() {
        tagsView.attributedText = makeLinkedTagViewText()
        tagsView.accessibilityLabel = Self.makeLinkedTagViewAccessibilityLabel(tagViewTagPairs)
        tagsView.accessibilityCustomActions = tagViewTagPairs.map { tagPair in
            .init(
                name: String.localizedStringWithFormat(
                    NSLocalizedString("status.accessibility.go-to-hashtag-%@", comment: ""),
                    Self.stripHash(tagPair.name)
                )
            ) { [weak self] _ in
                self?.viewModel?.tagSelected(tagPair.id)
                return true
            }
        }
    }

    /// Returns text with tappable hashtag links for each trailing or out-of-text tag.
    func makeLinkedTagViewText() -> NSAttributedString? {
        guard let viewModel = viewModel else { return nil }

        let text = NSMutableAttributedString()

        var firstTag = true
        for (tagId, tagText) in tagViewTagPairs {
            if !firstTag {
                // Explicitly non-attributed text prevents extending attribute runs from previous text.
                text.append(NSAttributedString(string: " "))
            }
            firstTag = false

            let linkAttributedString = NSMutableAttributedString(string: tagText)
            let linkRange = NSRange(location: 0, length: linkAttributedString.length)

            linkAttributedString.addAttribute(
                .link,
                value: AppUrl.tagTimeline(tagId).url,
                range: linkRange
            )
            linkAttributedString.addAttribute(
                .foregroundColor,
                value: Self.tagsViewLinkColor,
                range: linkRange
            )

            if viewModel.reasonTagIDs.contains(tagId) {
                // Make these tags stand out.
                if traitCollection.accessibilityContrast == .high {
                    linkAttributedString.addAttribute(
                        .underlineStyle,
                        // Without .rawValue, results in -[_SwiftValue integerValue]: unrecognized selector sent to instance
                        value: NSUnderlineStyle.single.rawValue,
                        range: linkRange
                    )
                    linkAttributedString.addAttribute(
                        .underlineColor,
                        value: UIColor.tintColor,
                        range: linkRange
                    )
                } else {
                    linkAttributedString.addAttribute(
                        .backgroundColor,
                        value: Self.tagsViewFollowedTagBackgroundColor,
                        range: linkRange
                    )
                }
            }

            text.append(linkAttributedString)
        }

        text.addAttribute(
            .font,
            value: UIFont.preferredFont(forTextStyle: isContextParent ? .callout : .footnote),
            range: NSRange(location: 0, length: text.length)
        )

        return text
    }

    /// Tag names extracted from links in status content don't necessarily start with a hash.
    /// Tag names from view models always do.
    /// Either way, for accessibility, we might need the bare version.
    static func stripHash(_ name: String) -> String {
        if name.hasPrefix("#") {
            return String(name["#".endIndex...])
        }
        return name
    }

    static func makeLinkedTagViewAccessibilityLabel(_ tagPairs: [TagPair]) -> String? {
        guard !tagPairs.isEmpty else { return nil }

        return String(
            tagPairs
                .map { tagPair in Self.stripHash(tagPair.name) }
                .joined(separator: ", ")
        )
    }

    /// De-emphasize links in tag view.
    /// Disabled if high contrast mode is on.
    static var tagsViewLinkColor: UIColor = .init { traitCollection in
        if traitCollection.accessibilityContrast == .high {
            return .tintColor
        }

        var h1: CGFloat = 0
        var s1: CGFloat = 0
        var b1: CGFloat = 0
        var a1: CGFloat = 0
        UIColor.tintColor.getHue(&h1, saturation: &s1, brightness: &b1, alpha: &a1)

        var s2: CGFloat = 0
        var b2: CGFloat = 0
        var a2: CGFloat = 0
        UIColor.secondaryLabel.getHue(nil, saturation: &s2, brightness: &b2, alpha: &a2)

        return .init(
            hue: h1,
            saturation: (s1 + s2) / 2,
            brightness: (b1 + b2) / 2,
            alpha: (a1 + a2) / 2
        )
    }

    /// Highlight followed tags in status text with transparent version of tags view link color.
    /// Disabled if high contrast mode is on.
    static var followedTagBackgroundColor: UIColor = .init { traitCollection in
        if traitCollection.accessibilityContrast == .high {
            return .clear
        }

        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        UIColor.tintColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)

        return .init(hue: h, saturation: s, brightness: b, alpha: a / 8)
    }

    /// Highlight followed tags in tags view with transparent version of tags view link color.
    /// Disabled if high contrast mode is on.
    static var tagsViewFollowedTagBackgroundColor: UIColor = .init { traitCollection in
        if traitCollection.accessibilityContrast == .high {
            return .clear
        }

        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        StatusBodyView.tagsViewLinkColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)

        return .init(hue: h, saturation: s, brightness: b, alpha: a / 8)
    }
}
