// Copyright © 2020 Metabolist. All rights reserved.

import Mastodon
import UIKit
import ViewModels

final class StatusBodyView: UIView {
    let spoilerTextLabel = AnimatedAttachmentLabel()
    let toggleShowContentButton = CapsuleButton()
    let contentTextView = TouchFallthroughTextView()
    let attachmentsView = AttachmentsView()
    let pollView = PollView()
    let cardView = CardView()

    /// Fold posts more than this many laid-out lines long.
    static let numLinesBeforeFolding: Int = 20

    /// Show this many lines of a folded post as a preview.
    static let numLinesFoldedPreview: Int = 2

    var viewModel: StatusViewModel? {
        didSet {
            guard let viewModel = viewModel else { return }

            let mutableContent = Self.adaptFont(style: contentTextStyle, attributed: viewModel.content)
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
            contentTextView.isHidden = contentTextView.text.isEmpty

            if viewModel.hasSpoiler {
                mutableSpoilerText.insert(emojis: viewModel.contentEmojis,
                                          view: spoilerTextLabel,
                                          identityContext: viewModel.identityContext)
                mutableSpoilerText.resizeAttachments(toLineHeight: spoilerTextLabel.font.lineHeight)
            }
            spoilerTextLabel.font = mutableSpoilerFont
            spoilerTextLabel.attributedText = mutableSpoilerText
            spoilerTextLabel.isHidden = !viewModel.hasSpoiler
            toggleShowContentButton.setTitle(
                shouldShowContent
                    ? NSLocalizedString("status.show-less", comment: "")
                    : NSLocalizedString("status.show-more", comment: ""),
                for: .normal)
            toggleShowContentButton.isHidden = (!viewModel.hasSpoiler
                    || viewModel.alwaysExpandSpoilers
                    || !viewModel.shouldShowContentWarningButton)
                && (!hasLongContent || !viewModel.foldLongContent)

            contentTextView.isHidden = viewModel.shouldHideDueToSpoiler && !shouldShowContent
            contentTextView.textContainer.lineBreakMode = .byTruncatingTail
            if shouldShowFirstContentLineAsPreview {
                contentTextView.textContainer.maximumNumberOfLines = Self.numLinesFoldedPreview
            } else {
                contentTextView.textContainer.maximumNumberOfLines = 0
            }

            attachmentsView.isHidden = viewModel.attachmentViewModels.isEmpty
            attachmentsView.viewModel = viewModel

            pollView.isHidden = viewModel.pollOptions.isEmpty || !shouldShowContent
            pollView.viewModel = viewModel
            pollView.isAccessibilityElement = !isContextParent || viewModel.hasVotedInPoll || viewModel.isPollExpired

            cardView.viewModel = viewModel.cardViewModel
            cardView.isHidden = viewModel.cardViewModel == nil || !shouldShowContent

            accessibilityAttributedLabel = accessibilityAttributedLabel(forceShowContent: false)

            var accessibilityCustomActions = [UIAccessibilityCustomAction]()

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

            self.accessibilityCustomActions =
                accessibilityCustomActions + attachmentsView.attachmentViewAccessibilityCustomActions
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
}

extension StatusBodyView {
    static func estimatedHeight(width: CGFloat,
                                identityContext: IdentityContext,
                                status: Status,
                                configuration: CollectionItem.StatusConfiguration) -> CGFloat {
        let contentFont = UIFont.preferredFont(forTextStyle: configuration.isContextParent ? .title3 : .callout)
        var height: CGFloat = 0

        var contentHeight = status.displayStatus.content.attributed.string.height(
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
                configuration: configuration)
        }

        // TODO: (Vyr) harmonize this with rich text patch later
        //  This would be so much more convenient if it took a StatusViewModel…
        //  For now, it duplicates a lot of code from non-static contexts in this class and from StatusViewModel.
        let hasSpoiler = !status.displayStatus.spoilerText.isEmpty
        let alwaysExpandSpoilers = identityContext.identity.preferences.readingExpandSpoilers
        let shouldHideDueToSpoiler = hasSpoiler && !alwaysExpandSpoilers

        let contentLines = contentHeight / contentFont.lineHeight
        let hasLongContent = contentLines > CGFloat(Self.numLinesBeforeFolding)
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
           !shouldShowContent,
           !forceShowContent {
            accessibilityAttributedLabel.appendWithSeparator(
                NSLocalizedString("status.content-warning.accessibility", comment: ""))

            accessibilityAttributedLabel.appendWithSeparator(spoilerText)
        } else if (!contentTextView.isHidden || forceShowContent), let content = contentTextView.attributedText {
            accessibilityAttributedLabel.append(content)
        }

        for view in [attachmentsView, pollView, cardView] where !view.isHidden {
            guard let viewAccessibilityLabel = view.accessibilityLabel else { continue }

            accessibilityAttributedLabel.appendWithSeparator(viewAccessibilityLabel)
        }

        return accessibilityAttributedLabel
    }

    /// Needs to be visible for accessibility info in parent view.
    /// Cannot be handled entirely from view model since view model is not aware of view width, font, etc.
    public var shouldShowContent: Bool {
        guard let viewModel = viewModel else {
            return false
        }

        guard viewModel.shouldHideDueToSpoiler || shouldHideDueToLongContent else {
            return true
        }

        return viewModel.showContentToggled
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

    private var isContextParent: Bool {
        viewModel?.configuration.isContextParent ?? false
    }

    private var contentTextStyle: UIFont.TextStyle {
        isContextParent ? .title3 : .callout
    }

    private var contentFont: UIFont {
        UIFont.preferredFont(forTextStyle: contentTextStyle)
    }

    var contentLines: CGFloat {
        guard let viewModel = viewModel else {
            return 0.0
        }

        // TODO: (Vyr) harmonize this with rich text patch later
        let contentHeight = viewModel.content.string.height(
            width: frame.width,
            font: contentFont
        )
        return contentHeight / contentFont.lineHeight
    }

    var hasLongContent: Bool {
        contentLines > CGFloat(Self.numLinesBeforeFolding)
    }

    var shouldHideDueToLongContent: Bool {
        guard let viewModel = viewModel else {
            return false
        }
        guard hasLongContent else {
            return false
        }

        return viewModel.identityContext.appPreferences.foldLongPosts
    }

    var shouldShowFirstContentLineAsPreview: Bool {
        shouldHideDueToLongContent
            && !(viewModel?.shouldHideDueToSpoiler ?? false)
            && !shouldShowContent
    }

    /// Get size of body text produced by `NSAttributedString`'s HTML parser.
    /// Default is observed height on macOS 13.
    static let htmlBodyTextHeight: CGFloat = (NSAttributedString(html: "x")?
        .attribute(.font, at: 0, effectiveRange: nil) as? UIFont)?
        .pointSize
    ?? 12.0

    /// Replace HTML parser fonts with equivalent system fonts, appropriately scaled.
    static func adaptFont(style: UIFont.TextStyle, attributed: NSAttributedString) -> NSMutableAttributedString {
        let systemFontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        let mutable = NSMutableAttributedString(attributedString: attributed)
        let entireString = NSRange(location: 0, length: mutable.length)
        mutable.enumerateAttribute(.font, in: entireString) { val, range, _ in
            guard let font = val as? UIFont else {
                return
            }
            let descriptor = font.fontDescriptor
            let size = descriptor.pointSize / htmlBodyTextHeight * systemFontDescriptor.pointSize
            var traits = descriptor.symbolicTraits
            traits.remove(.classMask)
            guard let newDescriptor = systemFontDescriptor.withSize(size).withSymbolicTraits(traits) else {
                return
            }
            let newFont = UIFont(descriptor: newDescriptor, size: 0.0)
            mutable.addAttribute(.font, value: newFont, range: range)
        }
        mutable.fixAttributes(in: entireString)
        return mutable
    }
}
