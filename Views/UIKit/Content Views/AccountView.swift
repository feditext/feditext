// Copyright © 2020 Metabolist. All rights reserved.

import Mastodon
import SDWebImage
import UIKit
import ViewModels

final class AccountView: UIView {
    let avatarImageView = SDAnimatedImageView()
    let displayNameLabel = AnimatedAttachmentLabel()
    let accountLabel = UILabel()

    let accountTypeStack = UIStackView()
    let accountTypeBotImageView = UIImageView()
    let accountTypeGroupImageView = UIImageView()
    /// Displays text explanation of account type.
    let accountTypeLabel = UILabel()

    let verifiedStack = UIStackView()
    /// Displays first verified link in profile, if there is one.
    let verifiedLabel = UILabel()

    let visibilityRelationshipStack = UIStackView()
    let visibilityRelationshipIcon = UIImageView()
    /// Displays text explanation of whether current user has blocked or muted this account.
    let visibilityRelationshipLabel = UILabel()

    let followRelationshipStack = UIStackView()
    let followRelationshipIcon = UIImageView()
    /// Displays text explanation of current user's relationship with this account.
    let followRelationshipLabel = UILabel()

    /// Displays first few display names of current user's follows who also follow this account.
    let familiarFollowersLabel = FamiliarFollowersLabel()

    let relationshipNoteStack = UIStackView()
    /// Displays the current user's note for this account.
    let relationshipNotes = UILabel()

    /// Displays the account's bio.
    let noteTextView = TouchFallthroughTextView()

    let acceptFollowRequestButton = UIButton()
    let rejectFollowRequestButton = UIButton()
    let muteButton = UIButton(type: .system)
    let unmuteButton = UIButton(type: .system)
    let blockButton = UIButton(type: .system)
    let unblockButton = UIButton(type: .system)

    private var accountConfiguration: AccountContentConfiguration

    init(configuration: AccountContentConfiguration) {
        self.accountConfiguration = configuration

        super.init(frame: .zero)

        initialSetup()
        applyAccountConfiguration()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AccountView {
    static func estimatedHeight(
        width: CGFloat,
        account: Account,
        configuration: CollectionItem.AccountConfiguration,
        relationship: Relationship?,
        familiarFollowers: [Account]
    ) -> CGFloat {
        var height = CGFloat.defaultSpacing * 2
            + .compactSpacing
            + account.displayName.height(width: width, font: .preferredFont(forTextStyle: .headline))
            + account.acct.height(width: width, font: .preferredFont(forTextStyle: .subheadline))

        if let relationshipNote = relationship?.note, !relationshipNote.isEmpty {
            height += relationshipNote.height(width: width, font: .preferredFont(forTextStyle: .subheadline))
        }

        if !familiarFollowers.isEmpty {
            height += familiarFollowers
                .prefix(4)
                .map { $0.displayName }
                .joined(separator: ", ")
                .height(
                    width: width,
                    font: .preferredFont(forTextStyle: .subheadline)
                )
        }

        if configuration == .withNote {
            height += .compactSpacing + account.note.attributed.string.height(
                width: width,
                font: .preferredFont(forTextStyle: .callout))
        }

        return max(height, .avatarDimension + .defaultSpacing * 2)
    }
}

extension AccountView: UIContentView {
    var configuration: UIContentConfiguration {
        get { accountConfiguration }
        set {
            guard let accountConfiguration = newValue as? AccountContentConfiguration else { return }

            self.accountConfiguration = accountConfiguration

            applyAccountConfiguration()
        }
    }
}

extension AccountView: UITextViewDelegate {
    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction) -> Bool {
        switch interaction {
        case .invokeDefaultAction:
            accountConfiguration.viewModel.urlSelected(URL)
            return false
        case .preview: return false
        case .presentActions: return false
        @unknown default: return false
        }
    }
}

private extension AccountView {
    // swiftlint:disable:next function_body_length
    func initialSetup() {
        let stackView = UIStackView()

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = .defaultSpacing
        stackView.alignment = .top

        stackView.addArrangedSubview(avatarImageView)

        avatarImageView.clipsToBounds = true
        
        // Apply displayAvatarShape to avatarImageView
        switch accountConfiguration.viewModel.identityContext.appPreferences.displayAvatarShape {
            case .circle:
                avatarImageView.layer.cornerRadius = .avatarDimension / 2
            case .roundedRectangle:
                avatarImageView.layer.cornerRadius = .avatarDimension / 8
        }

        accountTypeStack.axis = .horizontal
        accountTypeStack.spacing = .ultraCompactSpacing

        accountTypeStack.addArrangedSubview(accountTypeBotImageView)
        accountTypeBotImageView.image = .init(
            systemName: "cpu.fill",
            withConfiguration: UIImage.SymbolConfiguration(scale: .small)
        )
        accountTypeBotImageView.tintColor = .secondaryLabel
        accountTypeBotImageView.contentMode = .scaleAspectFit
        accountTypeBotImageView.adjustsImageSizeForAccessibilityContentSizeCategory = true
        accountTypeBotImageView.setContentHuggingPriority(.required, for: .horizontal)
        accountTypeBotImageView.setContentCompressionResistancePriority(.required, for: .horizontal)

        accountTypeStack.addArrangedSubview(accountTypeGroupImageView)
        accountTypeGroupImageView.image = .init(
            systemName: "person.3.fill",
            withConfiguration: UIImage.SymbolConfiguration(scale: .small)
        )
        accountTypeGroupImageView.tintColor = .secondaryLabel
        accountTypeGroupImageView.contentMode = .scaleAspectFit
        accountTypeGroupImageView.adjustsImageSizeForAccessibilityContentSizeCategory = true
        accountTypeGroupImageView.setContentHuggingPriority(.required, for: .horizontal)
        accountTypeGroupImageView.setContentCompressionResistancePriority(.required, for: .horizontal)

        accountTypeStack.addArrangedSubview(accountTypeLabel)
        accountTypeLabel.font = .preferredFont(forTextStyle: .footnote)
        accountTypeLabel.adjustsFontForContentSizeCategory = true
        accountTypeLabel.textColor = .secondaryLabel

        relationshipNoteStack.axis = .horizontal
        // .firstBaseline makes the view infinitely large vertically for some reason.
        relationshipNoteStack.alignment = .center
        relationshipNoteStack.spacing = .defaultSpacing
        relationshipNoteStack.layer.borderColor = UIColor.separator.cgColor
        relationshipNoteStack.layer.borderWidth = .hairline
        relationshipNoteStack.layer.cornerRadius = .defaultCornerRadius
        relationshipNoteStack.isLayoutMarginsRelativeArrangement = true
        relationshipNoteStack.directionalLayoutMargins = .init(
            top: .defaultSpacing,
            leading: .defaultSpacing,
            bottom: .defaultSpacing,
            trailing: .defaultSpacing
        )

        let verticalStackView = UIStackView()

        stackView.addArrangedSubview(verticalStackView)
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        verticalStackView.axis = .vertical
        verticalStackView.spacing = .compactSpacing
        verticalStackView.addArrangedSubview(displayNameLabel)
        verticalStackView.addArrangedSubview(accountLabel)
        verticalStackView.addArrangedSubview(verifiedStack)
        verticalStackView.addArrangedSubview(accountTypeStack)
        verticalStackView.addArrangedSubview(visibilityRelationshipStack)
        verticalStackView.addArrangedSubview(followRelationshipStack)
        verticalStackView.addArrangedSubview(familiarFollowersLabel)
        verticalStackView.addArrangedSubview(relationshipNoteStack)
        verticalStackView.addArrangedSubview(noteTextView)

        displayNameLabel.numberOfLines = 0
        displayNameLabel.font = .preferredFont(forTextStyle: .headline)
        displayNameLabel.adjustsFontForContentSizeCategory = true

        accountLabel.numberOfLines = 0
        accountLabel.font = .preferredFont(forTextStyle: .subheadline)
        accountLabel.adjustsFontForContentSizeCategory = true
        accountLabel.textColor = .secondaryLabel

        verifiedStack.axis = .horizontal
        verifiedStack.alignment = .center
        verifiedStack.spacing = .ultraCompactSpacing

        let verifiedIcon = UIImageView()
        verifiedStack.addArrangedSubview(verifiedIcon)
        verifiedIcon.image = .init(
            systemName: "checkmark",
            withConfiguration: UIImage.SymbolConfiguration(scale: .small)
        )
        verifiedIcon.tintColor = .systemGreen
        verifiedIcon.accessibilityLabel = NSLocalizedString("account.verified", comment: "")
        verifiedIcon.setContentHuggingPriority(.required, for: .horizontal)
        verifiedIcon.setContentHuggingPriority(.required, for: .vertical)
        verifiedIcon.adjustsImageSizeForAccessibilityContentSizeCategory = true

        verifiedStack.addArrangedSubview(verifiedLabel)
        verifiedLabel.font = .preferredFont(forTextStyle: .footnote)
        verifiedLabel.adjustsFontForContentSizeCategory = true
        verifiedLabel.textColor = .systemGreen

        visibilityRelationshipStack.axis = .horizontal
        visibilityRelationshipStack.alignment = .center
        visibilityRelationshipStack.spacing = .ultraCompactSpacing

        visibilityRelationshipStack.addArrangedSubview(visibilityRelationshipIcon)
        visibilityRelationshipIcon.tintColor = .secondaryLabel
        visibilityRelationshipIcon.setContentHuggingPriority(.required, for: .horizontal)
        visibilityRelationshipIcon.setContentHuggingPriority(.required, for: .vertical)
        visibilityRelationshipIcon.adjustsImageSizeForAccessibilityContentSizeCategory = true

        visibilityRelationshipStack.addArrangedSubview(visibilityRelationshipLabel)
        visibilityRelationshipLabel.font = .preferredFont(forTextStyle: .footnote)
        visibilityRelationshipLabel.adjustsFontForContentSizeCategory = true
        visibilityRelationshipLabel.textColor = .secondaryLabel

        followRelationshipStack.axis = .horizontal
        followRelationshipStack.alignment = .center
        followRelationshipStack.spacing = .ultraCompactSpacing

        followRelationshipStack.addArrangedSubview(followRelationshipIcon)
        followRelationshipIcon.tintColor = .secondaryLabel
        followRelationshipIcon.setContentHuggingPriority(.required, for: .horizontal)
        followRelationshipIcon.setContentHuggingPriority(.required, for: .vertical)
        followRelationshipIcon.adjustsImageSizeForAccessibilityContentSizeCategory = true

        followRelationshipStack.addArrangedSubview(followRelationshipLabel)
        followRelationshipLabel.font = .preferredFont(forTextStyle: .footnote)
        followRelationshipLabel.adjustsFontForContentSizeCategory = true
        followRelationshipLabel.textColor = .secondaryLabel

        familiarFollowersLabel.numberOfLines = 0
        familiarFollowersLabel.font = .preferredFont(forTextStyle: .footnote)
        familiarFollowersLabel.adjustsFontForContentSizeCategory = true
        familiarFollowersLabel.textColor = .secondaryLabel

        let relationshipNoteIcon = UIImageView()
        relationshipNoteStack.addArrangedSubview(relationshipNoteIcon)
        relationshipNoteIcon.image = .init(systemName: "note.text")
        relationshipNoteIcon.tintColor = .secondaryLabel
        relationshipNoteIcon.accessibilityLabel = NSLocalizedString("account.note", comment: "")
        relationshipNoteIcon.setContentHuggingPriority(.required, for: .horizontal)
        relationshipNoteIcon.setContentHuggingPriority(.required, for: .vertical)
        relationshipNoteIcon.adjustsImageSizeForAccessibilityContentSizeCategory = true

        relationshipNoteStack.addArrangedSubview(relationshipNotes)
        relationshipNotes.backgroundColor = .clear
        relationshipNotes.font = .preferredFont(forTextStyle: .subheadline)
        relationshipNotes.textColor = .secondaryLabel
        relationshipNotes.adjustsFontForContentSizeCategory = true
        relationshipNotes.numberOfLines = 0

        noteTextView.backgroundColor = .clear
        noteTextView.delegate = self

        let largeTitlePointSize = UIFont.preferredFont(forTextStyle: .largeTitle).pointSize

        stackView.addArrangedSubview(acceptFollowRequestButton)
        acceptFollowRequestButton.setImage(
            UIImage(systemName: "checkmark.circle",
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: largeTitlePointSize)),
            for: .normal)
        acceptFollowRequestButton.setContentHuggingPriority(.required, for: .horizontal)
        acceptFollowRequestButton.addAction(
            UIAction { [weak self] _ in self?.accountConfiguration.viewModel.acceptFollowRequest() },
            for: .touchUpInside)

        stackView.addArrangedSubview(rejectFollowRequestButton)
        rejectFollowRequestButton.setImage(
            UIImage(systemName: "xmark.circle",
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: largeTitlePointSize)),
            for: .normal)
        rejectFollowRequestButton.tintColor = .systemRed
        rejectFollowRequestButton.setContentHuggingPriority(.required, for: .horizontal)
        rejectFollowRequestButton.addAction(
            UIAction { [weak self] _ in self?.accountConfiguration.viewModel.rejectFollowRequest() },
            for: .touchUpInside)

        stackView.addArrangedSubview(muteButton)
        muteButton.setTitle(NSLocalizedString("account.mute", comment: ""), for: .normal)
        muteButton.titleLabel?.adjustsFontForContentSizeCategory = true
        muteButton.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        muteButton.addAction(
            UIAction { [weak self] _ in self?.accountConfiguration.viewModel.confirmMute() },
            for: .touchUpInside)
        muteButton.isHidden = true

        stackView.addArrangedSubview(unmuteButton)
        unmuteButton.setTitle(NSLocalizedString("account.unmute", comment: ""), for: .normal)
        unmuteButton.titleLabel?.adjustsFontForContentSizeCategory = true
        unmuteButton.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        unmuteButton.addAction(
            UIAction { [weak self] _ in self?.accountConfiguration.viewModel.confirmUnmute() },
            for: .touchUpInside)
        unmuteButton.isHidden = true

        stackView.addArrangedSubview(blockButton)
        blockButton.setTitle(NSLocalizedString("account.block", comment: ""), for: .normal)
        blockButton.titleLabel?.adjustsFontForContentSizeCategory = true
        blockButton.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        blockButton.addAction(
            UIAction { [weak self] _ in self?.accountConfiguration.viewModel.confirmBlock() },
            for: .touchUpInside)
        blockButton.isHidden = true

        stackView.addArrangedSubview(unblockButton)
        unblockButton.setTitle(NSLocalizedString("account.unblock", comment: ""), for: .normal)
        unblockButton.titleLabel?.adjustsFontForContentSizeCategory = true
        unblockButton.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        unblockButton.addAction(
            UIAction { [weak self] _ in self?.accountConfiguration.viewModel.confirmUnblock() },
            for: .touchUpInside)
        unblockButton.isHidden = true

        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: .avatarDimension),
            avatarImageView.heightAnchor.constraint(equalToConstant: .avatarDimension),
            acceptFollowRequestButton.widthAnchor.constraint(greaterThanOrEqualToConstant: .avatarDimension),
            acceptFollowRequestButton.heightAnchor.constraint(greaterThanOrEqualToConstant: .avatarDimension),
            rejectFollowRequestButton.widthAnchor.constraint(greaterThanOrEqualToConstant: .avatarDimension),
            rejectFollowRequestButton.heightAnchor.constraint(greaterThanOrEqualToConstant: .avatarDimension),
            muteButton.heightAnchor.constraint(greaterThanOrEqualToConstant: .avatarDimension),
            unmuteButton.heightAnchor.constraint(greaterThanOrEqualToConstant: .avatarDimension),
            blockButton.heightAnchor.constraint(greaterThanOrEqualToConstant: .avatarDimension),
            unblockButton.heightAnchor.constraint(greaterThanOrEqualToConstant: .avatarDimension),
            stackView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: readableContentGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: readableContentGuide.bottomAnchor),
            stackView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor)
        ])

        isAccessibilityElement = true
    }

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func applyAccountConfiguration() {
        let viewModel = accountConfiguration.viewModel

        avatarImageView.sd_setImage(with: viewModel.avatarURL(profile: false))
        switch accountConfiguration.viewModel.identityContext.appPreferences.displayAvatarShape {
            case .circle:
                avatarImageView.layer.cornerRadius = .avatarDimension / 2
            case .roundedRectangle:
                avatarImageView.layer.cornerRadius = .avatarDimension / 8
        }

        let mutableDisplayName = NSMutableAttributedString(string: viewModel.displayName)

        mutableDisplayName.insert(emojis: viewModel.emojis,
                                  view: displayNameLabel,
                                  identityContext: viewModel.identityContext)
        mutableDisplayName.resizeAttachments(toLineHeight: displayNameLabel.font.lineHeight)
        displayNameLabel.attributedText = mutableDisplayName

        displayNameLabel.isHidden = viewModel.displayName.isEmpty

        accountLabel.text = viewModel.accountName

        accountTypeStack.isHidden = !(viewModel.isBot || viewModel.isGroup)
        accountTypeBotImageView.isHidden = !viewModel.isBot
        accountTypeGroupImageView.isHidden = !viewModel.isGroup
        accountTypeLabel.text = viewModel.accountTypeText

        if let firstVerifiedField = viewModel.fields.first(where: { $0.verifiedAt != nil }) {
            verifiedStack.isHidden = false
            // Full HTML display and tap support not necessary: we're just showing a URL in this case.
            verifiedLabel.text = firstVerifiedField.value.attributed.string
        } else {
            verifiedStack.isHidden = true
        }

        if let relationshipNote = viewModel.relationship?.note, !relationshipNote.isEmpty {
            relationshipNoteStack.isHidden = false
            relationshipNotes.text = relationshipNote
        } else {
            relationshipNoteStack.isHidden = true
        }

        if viewModel.configuration == .withNote {
            let noteFont = UIFont.preferredFont(forTextStyle: .callout)
            let mutableNote = NSMutableAttributedString(attributedString: viewModel.note)
            let noteRange = NSRange(location: 0, length: mutableNote.length)

            mutableNote.removeAttribute(.font, range: noteRange)
            mutableNote.addAttributes(
                [.font: noteFont as Any,
                 .foregroundColor: UIColor.label],
                range: noteRange)
            mutableNote.insert(emojis: viewModel.emojis, view: noteTextView, identityContext: viewModel.identityContext)
            mutableNote.resizeAttachments(toLineHeight: noteFont.lineHeight)

            noteTextView.attributedText = mutableNote
            noteTextView.isHidden = false
        } else {
            noteTextView.isHidden = true
        }

        let isFollowRequest = viewModel.configuration == .followRequest

        acceptFollowRequestButton.isHidden = !isFollowRequest
        rejectFollowRequestButton.isHidden = !isFollowRequest

        let followRelationshipShown: Bool
        if !viewModel.isSelf, let relationship = viewModel.relationship {
            if viewModel.configuration == .mute {
                muteButton.isHidden = relationship.muting
                unmuteButton.isHidden = !relationship.muting
                blockButton.isHidden = true
                unblockButton.isHidden = true
            } else if viewModel.configuration == .block {
                muteButton.isHidden = true
                unmuteButton.isHidden = true
                blockButton.isHidden = relationship.blocking
                unblockButton.isHidden = !relationship.blocking
            } else {
                if relationship.blocking {
                    visibilityRelationshipIcon.image = .init(
                        systemName: "slash.circle",
                        withConfiguration: UIImage.SymbolConfiguration(scale: .small)
                    )
                    visibilityRelationshipLabel.text = NSLocalizedString("account.blocked", comment: "")
                    visibilityRelationshipStack.isHidden = false
                } else if relationship.domainBlocking {
                    visibilityRelationshipIcon.image = .init(
                        systemName: "slash.circle",
                        withConfiguration: UIImage.SymbolConfiguration(scale: .small)
                    )
                    visibilityRelationshipLabel.text = NSLocalizedString("account.domain-blocked", comment: "")
                    visibilityRelationshipStack.isHidden = false
                } else if relationship.muting {
                    visibilityRelationshipIcon.image = .init(
                        systemName: "speaker.slash",
                        withConfiguration: UIImage.SymbolConfiguration(scale: .small)
                    )
                    visibilityRelationshipLabel.text = NSLocalizedString("account.muted", comment: "")
                    visibilityRelationshipStack.isHidden = false
                } else {
                    visibilityRelationshipStack.isHidden = true
                }
            }

            if relationship.following && relationship.followedBy {
                followRelationshipIcon.image = .init(
                    systemName: "arrow.left.arrow.right.square.fill",
                    withConfiguration: UIImage.SymbolConfiguration(scale: .small)
                )
                followRelationshipLabel.text = NSLocalizedString("account.relationship.mutuals", comment: "")
                followRelationshipStack.isHidden = false
                followRelationshipShown = true
            } else if relationship.following {
                followRelationshipIcon.image = .init(
                    systemName: "arrow.left.square.fill",
                    withConfiguration: UIImage.SymbolConfiguration(scale: .small)
                )
                followRelationshipLabel.text = NSLocalizedString("account.relationship.following", comment: "")
                followRelationshipStack.isHidden = false
                followRelationshipShown = true
            } else if relationship.followedBy {
                followRelationshipIcon.image = .init(
                    systemName: "arrow.right.square.fill",
                    withConfiguration: UIImage.SymbolConfiguration(scale: .small)
                )
                followRelationshipLabel.text = NSLocalizedString("account.relationship.followed-by", comment: "")
                followRelationshipStack.isHidden = false
                followRelationshipShown = true
            } else {
                followRelationshipStack.isHidden = true
                followRelationshipShown = false
            }
        } else {
            muteButton.isHidden = true
            unmuteButton.isHidden = true
            blockButton.isHidden = true
            unblockButton.isHidden = true
            followRelationshipStack.isHidden = true
            followRelationshipShown = false
        }

        familiarFollowersLabel.identityContext = viewModel.identityContext
        if !viewModel.isSelf, !followRelationshipShown, !viewModel.familiarFollowers.isEmpty {
            familiarFollowersLabel.isHidden = false
            familiarFollowersLabel.accounts = viewModel.familiarFollowers
        } else {
            familiarFollowersLabel.isHidden = true
        }

        let accessibilityAttributedLabel = NSMutableAttributedString(string: "")

        if !displayNameLabel.isHidden, let displayName = displayNameLabel.attributedText {
            accessibilityAttributedLabel.append(displayName)
            accessibilityAttributedLabel.appendWithSeparator(viewModel.accountName)
        } else {
            accessibilityAttributedLabel.appendWithSeparator(viewModel.accountName)
        }

        if !visibilityRelationshipStack.isHidden, let visibility = visibilityRelationshipLabel.attributedText {
            accessibilityAttributedLabel.appendWithSeparator(visibility)
        }

        if !followRelationshipStack.isHidden, let relationship = followRelationshipLabel.attributedText {
            accessibilityAttributedLabel.appendWithSeparator(relationship)
        }

        if !familiarFollowersLabel.isHidden, let familiarFollowers = familiarFollowersLabel.attributedText {
            accessibilityAttributedLabel.appendWithSeparator(familiarFollowers)
        }

        if !verifiedStack.isHidden, let verifiedValue = verifiedLabel.attributedText {
            accessibilityAttributedLabel.appendWithSeparator(NSLocalizedString("account.verified", comment: ""))
            accessibilityAttributedLabel.appendWithSeparator(verifiedValue)
        }

        if !relationshipNoteStack.isHidden, let relationshipNote = relationshipNotes.attributedText {
            accessibilityAttributedLabel.appendWithSeparator(relationshipNote)
        }

        if !noteTextView.isHidden, let note = noteTextView.attributedText {
            accessibilityAttributedLabel.appendWithSeparator(note)
        }

        self.accessibilityAttributedLabel = accessibilityAttributedLabel

        if isFollowRequest {
            accessibilityCustomActions = [
                UIAccessibilityCustomAction(
                    name: NSLocalizedString(
                        "account.accept-follow-request-button.accessibility-label",
                        comment: "")) { [weak self] _ in
                        self?.accountConfiguration.viewModel.acceptFollowRequest()

                        return true
                    },
                UIAccessibilityCustomAction(
                    name: NSLocalizedString(
                        "account.reject-follow-request-button.accessibility-label",
                        comment: "")) { [weak self] _ in
                        self?.accountConfiguration.viewModel.rejectFollowRequest()

                        return true
                    }]
        } else if viewModel.configuration == .mute, let relationship = viewModel.relationship {
            if relationship.muting {
                accessibilityCustomActions = [
                    UIAccessibilityCustomAction(
                        name: NSLocalizedString(
                            "account.unmute",
                            comment: "")) { [weak self] _ in
                            self?.accountConfiguration.viewModel.confirmUnmute()

                            return true
                        }]
            } else {
                accessibilityCustomActions = [
                    UIAccessibilityCustomAction(
                        name: NSLocalizedString(
                            "account.mute",
                            comment: "")) { [weak self] _ in
                            self?.accountConfiguration.viewModel.confirmMute()

                            return true
                        }]
            }
        } else if viewModel.configuration == .block, let relationship = viewModel.relationship {
            if relationship.blocking {
                accessibilityCustomActions = [
                    UIAccessibilityCustomAction(
                        name: NSLocalizedString(
                            "account.unblock",
                            comment: "")) { [weak self] _ in
                            self?.accountConfiguration.viewModel.confirmUnblock()

                            return true
                        }]
            } else {
                accessibilityCustomActions = [
                    UIAccessibilityCustomAction(
                        name: NSLocalizedString(
                            "account.block",
                            comment: "")) { [weak self] _ in
                            self?.accountConfiguration.viewModel.confirmBlock()

                            return true
                        }]
            }
        } else {
            accessibilityCustomActions = []
        }
    }
}
