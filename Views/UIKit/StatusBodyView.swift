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

    /// Status content styled for this context and with trailing hashtags removed (if applicable),
    /// but without hashtag styles that may change based on the accessibility contrast.
    private var content: AttributedString?
    private var tagViewTagPairs = [StatusViewModel.TagPair]()

    private var cancellables = Set<AnyCancellable>()

    /// Show this many lines of a folded post as a preview.
    static let numLinesFoldedPreview: Int = 2

    var viewModel: StatusViewModel? {
        didSet {
            guard let viewModel = viewModel else { return }

            let foldTrailingHashtags = viewModel.identityContext.appPreferences.foldTrailingHashtags
            let outOfTextTagPairs = viewModel.outOfTextTags

            var content = viewModel.content
            let (trailerStart, trailingTagPairs) = viewModel.splitTrailingHashtags
            if trailerStart < content.endIndex {
                content = AttributedString(content[content.startIndex..<trailerStart])
            }
            content.foregroundColor = .label
            self.content = content.formatSiren(contentTextStyle)
            updateContentView()

            contentTextView.shouldFallthrough = !isContextParent
            contentTextView.accessibilityLanguage = viewModel.language
            contentTextView.isHidden = contentTextView.text.isEmpty

            let mutableSpoilerText = NSMutableAttributedString(string: viewModel.spoilerText)
            let mutableSpoilerFont = UIFont.preferredFont(forTextStyle: contentTextStyle).bold()
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

            for (url, range) in content.runs[\.link] {
                guard let url = url else { continue }

                accessibilityCustomActions.append(
                    UIAccessibilityCustomAction(
                        name: String.localizedStringWithFormat(
                            NSLocalizedString("accessibility.activate-link-%@", comment: ""),
                            String(content[range].characters)
                        )
                    ) { [weak self] _ in
                        guard let contentTextView = self?.contentTextView,
                              let content = self?.content
                        else { return false }

                        _ = contentTextView.delegate?.textView?(
                            contentTextView,
                            shouldInteractWith: url,
                            in: NSRange(range, in: content),
                            interaction: .invokeDefaultAction
                        )

                        return true
                    }
                )
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

        updateContentView()
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
        tagsView.linkTextAttributes.removeValue(forKey: .underlineColor)
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
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    var isContextParent: Bool {
        viewModel?.configuration.isContextParent ?? false
    }

    var contentTextStyle: UIFont.TextStyle {
        isContextParent ? .title3 : .callout
    }

    /// Update the content view when the content or the accessibility contrast changes.
    func updateContentView() {
        guard var mutableContent = content,
              let viewModel = viewModel
        else { return }

        // Make followed hashtags stand out.
        for (tagID, range) in mutableContent.runs[\.hashtag] {
            guard let tagID = tagID else { continue }

            if viewModel.reasonTagIDs.contains(tagID) {
                if traitCollection.accessibilityContrast == .high {
                    mutableContent[range].uiKit.underlineStyle = .single
                    mutableContent[range].uiKit.underlineColor = .tintColor
                } else {
                    mutableContent[range].backgroundColor = Self.followedTagBackgroundColor
                }
            }
        }

        let nsMutableContent = (try? NSMutableAttributedString(mutableContent, including: \.all)) ?? .init()
        nsMutableContent.insert(
            emojis: viewModel.contentEmojis,
            view: contentTextView,
            identityContext: viewModel.identityContext
        )
        let contentFont = UIFont.preferredFont(forTextStyle: contentTextStyle)
        nsMutableContent.resizeAttachments(toLineHeight: contentFont.lineHeight)
        contentTextView.attributedText = nsMutableContent
    }

    /// Update the tag view when the tag list, the user's list of followed tags, or the accessibility contrast changes.
    func updateTagView() {
        tagsView.attributedText = linkedTagViewText.flatMap { try? NSAttributedString($0, including: \.all) }
        tagsView.accessibilityLabel = makeLinkedTagViewAccessibilityLabel()
        tagsView.accessibilityCustomActions = tagViewTagPairs.map { tagPair in
            .init(
                name: String.localizedStringWithFormat(
                    NSLocalizedString("status.accessibility.go-to-hashtag-%@", comment: ""),
                    tagPair.name
                )
            ) { [weak self] _ in
                self?.viewModel?.tagSelected(tagPair.id)
                return true
            }
        }
    }

    /// Returns text with tappable hashtag links for each trailing or out-of-text tag.
    var linkedTagViewText: AttributedString? {
        guard let reasonTagIDs = viewModel?.reasonTagIDs else { return nil }

        let highContrast = traitCollection.accessibilityContrast == .high
        var text = tagViewTagPairs.lazy.map { (tagID, tagText) in
                var part = AttributedString("#" + tagText)
                part.link = AppUrl.tagTimeline(tagID).url
                part.foregroundColor = Self.tagsViewLinkColor

                if reasonTagIDs.contains(tagID) {
                    // Make followed tags stand out.
                    if highContrast {
                        part.uiKit.underlineStyle = .single
                        part.uiKit.underlineColor = .tintColor
                    } else {
                        part.backgroundColor = Self.tagsViewFollowedTagBackgroundColor
                    }
                }
                return part
            }
            .joined(separator: " ")

        text.font = UIFont.preferredFont(forTextStyle: isContextParent ? .callout : .footnote)

        return text
    }

    /// Return a comma-separated list of hashtags without leading `#`,
    /// also indicating which ones the user follows.
    func makeLinkedTagViewAccessibilityLabel() -> String? {
        guard let viewModel = viewModel,
              !tagViewTagPairs.isEmpty
        else { return nil }

        return String(
            tagViewTagPairs.lazy.map { tagPair in
                    if viewModel.reasonTagIDs.contains(tagPair.id) {
                        String.localizedStringWithFormat(
                            NSLocalizedString("status.accessibility.followed-hashtag-%@", comment: ""),
                            tagPair.name
                        )
                    } else {
                        tagPair.name
                    }
                }
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

        let aDivisor = traitCollection.userInterfaceStyle == .dark ? 3.0 : 6.0

        return .init(hue: h, saturation: s, brightness: b, alpha: a / aDivisor)
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

        let aDivisor = traitCollection.userInterfaceStyle == .dark ? 3.0 : 6.0

        return .init(hue: h, saturation: s, brightness: b, alpha: a / aDivisor)
    }
}
