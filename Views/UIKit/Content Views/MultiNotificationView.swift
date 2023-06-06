// Copyright © 2023 Vyr Cossont. All rights reserved.

import Mastodon
import SDWebImage
import UIKit
import ViewModels

/// Display up to this many avatars.
private let maxAvatarCount: Int = 8

final class MultiNotificationView: UIView {
    private let iconImageView = UIImageView()
    /// Vertical overlapping stack of first few avatars related to this group of notifications.
    private let avatarStackView = UIStackView()
    /// Image views for those avatars.
    private var avatarImageViews: [SDAnimatedImageView] = []
    /// Opens the list of all accounts related to this group of notifications.
    private let avatarButton = UIButton()
    private let typeLabel = AnimatedAttachmentLabel()
    private let timeLabel = UILabel()
    private let statusBodyView = StatusBodyView()
    private var multiNotificationConfiguration: MultiNotificationContentConfiguration

    init(configuration: MultiNotificationContentConfiguration) {
        multiNotificationConfiguration = configuration

        super.init(frame: .zero)

        initialSetup()
        applyMultiNotificationConfiguration()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MultiNotificationView {
    static func estimatedHeight(
        width: CGFloat,
        identityContext: IdentityContext,
        notifications: [MastodonNotification],
        status: Status?
    ) -> CGFloat {
        let bodyWidth = width - .defaultSpacing - .avatarDimension

        var height = CGFloat.defaultSpacing * 2
            + UIFont.preferredFont(forTextStyle: .headline).lineHeight
            + .compactSpacing

        let statusHeight: CGFloat
        if let status = status {
            statusHeight = StatusBodyView.estimatedHeight(
                width: bodyWidth,
                identityContext: identityContext,
                status: status,
                configuration: .default)
        } else {
            statusHeight = 0
        }

        let avatarCount = max(notifications.count, maxAvatarCount)
        let avatarHeight: CGFloat = .avatarDimension + CGFloat(avatarCount - 1) * .defaultSpacing

        height += max(statusHeight, avatarHeight)

        return height
    }
}

extension MultiNotificationView: UIContentView {
    var configuration: UIContentConfiguration {
        get { multiNotificationConfiguration }
        set {
            guard let notificationConfiguration = newValue as? MultiNotificationContentConfiguration else { return }

            self.multiNotificationConfiguration = notificationConfiguration

            applyMultiNotificationConfiguration()
        }
    }
}

private extension MultiNotificationView {
    // swiftlint:disable function_body_length
    func initialSetup() {
        let containerStackView = UIStackView()
        let sideStackView = UIStackView()
        let typeTimeStackView = UIStackView()
        let mainStackView = UIStackView()

        avatarStackView.translatesAutoresizingMaskIntoConstraints = false
        avatarStackView.axis = .vertical
        avatarStackView.spacing = .defaultSpacing - .avatarDimension

        var avatarConstraints: [NSLayoutConstraint] = []
        for i in 0...maxAvatarCount {
            /// Display a pseudo-shadow on the bottom edge of each avatar so they don't blend into each other.
            let avatarContainerView = UIView()
            avatarStackView.addArrangedSubview(avatarContainerView)
            avatarStackView.sendSubviewToBack(avatarContainerView)
            avatarContainerView.translatesAutoresizingMaskIntoConstraints = false
            avatarContainerView.backgroundColor = .systemBackground
            avatarContainerView.clipsToBounds = true

            let avatarImageView = SDAnimatedImageView()
            avatarContainerView.addSubview(avatarImageView)
            avatarImageView.translatesAutoresizingMaskIntoConstraints = false
            
            // Apply displayAvatarShape to avatarImageView
            switch multiNotificationConfiguration.viewModel.identityContext.appPreferences.displayAvatarShape {
                case .circle:
                    avatarImageView.layer.cornerRadius = .avatarDimension / 2
                case .roundedRectangle:
                    avatarImageView.layer.cornerRadius = .avatarDimension / 8
            }
            
            avatarImageView.clipsToBounds = true
            avatarImageView.alpha = CGFloat(maxAvatarCount - i) / CGFloat(maxAvatarCount)

            avatarImageViews.append(avatarImageView)
            avatarConstraints.append(contentsOf: [
                avatarContainerView.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
                avatarContainerView.bottomAnchor.constraint(
                    equalTo: avatarImageView.bottomAnchor,
                    constant: .defaultShadowRadius
                ),
                avatarContainerView.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor),
                avatarContainerView.trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor),
                avatarImageView.widthAnchor.constraint(equalToConstant: .avatarDimension),
                avatarImageView.heightAnchor.constraint(equalToConstant: .avatarDimension)
            ])
        }

        avatarStackView.addSubview(avatarButton)
        avatarButton.translatesAutoresizingMaskIntoConstraints = false
        avatarButton.setBackgroundImage(.highlightedButtonBackground, for: .highlighted)
        avatarButton.layer.cornerRadius = .avatarDimension / 2
        avatarButton.clipsToBounds = true
        avatarButton.addAction(
            UIAction { [weak self] _ in self?.multiNotificationConfiguration.viewModel.showAccounts() },
            for: .touchUpInside
        )

        addSubview(containerStackView)
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.spacing = .defaultSpacing
        containerStackView.alignment = .top

        sideStackView.axis = .vertical
        sideStackView.alignment = .trailing
        sideStackView.spacing = .compactSpacing
        sideStackView.addArrangedSubview(iconImageView)
        sideStackView.addArrangedSubview(avatarStackView)
        containerStackView.addArrangedSubview(sideStackView)

        typeTimeStackView.spacing = .compactSpacing
        typeTimeStackView.alignment = .top

        mainStackView.axis = .vertical
        mainStackView.spacing = .compactSpacing
        typeTimeStackView.addArrangedSubview(typeLabel)
        typeTimeStackView.addArrangedSubview(timeLabel)
        mainStackView.addArrangedSubview(typeTimeStackView)
        mainStackView.addArrangedSubview(statusBodyView)
        containerStackView.addArrangedSubview(mainStackView)

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.setContentHuggingPriority(.required, for: .horizontal)

        typeLabel.font = .preferredFont(forTextStyle: .headline)
        typeLabel.adjustsFontForContentSizeCategory = true
        typeLabel.numberOfLines = 0

        timeLabel.font = .preferredFont(forTextStyle: .subheadline)
        timeLabel.adjustsFontForContentSizeCategory = true
        timeLabel.textColor = .secondaryLabel
        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        timeLabel.setContentHuggingPriority(.required, for: .horizontal)

        statusBodyView.alpha = 0.5
        statusBodyView.isUserInteractionEnabled = false

        NSLayoutConstraint.activate([
            containerStackView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            containerStackView.topAnchor.constraint(equalTo: readableContentGuide.topAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: readableContentGuide.bottomAnchor),
            avatarStackView.widthAnchor.constraint(equalToConstant: .avatarDimension),
            avatarButton.topAnchor.constraint(equalTo: avatarStackView.topAnchor),
            avatarButton.bottomAnchor.constraint(equalTo: avatarStackView.bottomAnchor),
            avatarButton.leadingAnchor.constraint(equalTo: avatarStackView.leadingAnchor),
            avatarButton.trailingAnchor.constraint(equalTo: avatarStackView.trailingAnchor),
            sideStackView.widthAnchor.constraint(equalToConstant: .avatarDimension),
            iconImageView.centerYAnchor.constraint(equalTo: typeLabel.centerYAnchor)
        ] + avatarConstraints)

        isAccessibilityElement = true
    }

    func applyMultiNotificationConfiguration() {
        let viewModel = multiNotificationConfiguration.viewModel

        let displayedAccountViewModels = viewModel.accountViewModels.prefix(maxAvatarCount)
        for (i, avatarImageView) in avatarImageViews.enumerated() {
            if i < displayedAccountViewModels.count {
                avatarImageView.sd_setImage(with: displayedAccountViewModels[i].avatarURL())
                avatarImageView.superview?.isHidden = false
                
                // Apply displayAvatarShape to avatarImageView
                switch viewModel.identityContext.appPreferences.displayAvatarShape {
                    case .circle:
                        avatarImageView.layer.cornerRadius = .avatarDimension / 2
                    case .roundedRectangle:
                        avatarImageView.layer.cornerRadius = .avatarDimension / 8
                }
            } else {
                avatarImageView.sd_setImage(with: nil)
                avatarImageView.superview?.isHidden = true
            }
        }

        let statusWord = viewModel.identityContext.appPreferences.statusWord

        switch viewModel.type {
        case .follow:
            typeLabel.text = String.localizedStringWithFormat(
                NSLocalizedString("notifications.accounts-followed-you-%ld", comment: ""),
                viewModel.count
            )
            iconImageView.tintColor = nil
        case .reblog:
            let template: String
            switch statusWord {
            case .post:
                template = NSLocalizedString("notifications.accounts-reblogged-your-status-%ld.post", comment: "")
            case .toot:
                template = NSLocalizedString("notifications.accounts-reblogged-your-status-%ld.toot", comment: "")
            }
            typeLabel.text = String.localizedStringWithFormat(template, viewModel.count)
            iconImageView.tintColor = .systemGreen
        case .favourite:
            let template: String
            switch statusWord {
            case .post:
                template = NSLocalizedString("notifications.accounts-favourited-your-status-%ld.post", comment: "")
            case .toot:
                template = NSLocalizedString("notifications.accounts-favourited-your-status-%ld.toot", comment: "")
            }
            typeLabel.text = String.localizedStringWithFormat(template, viewModel.count)
            iconImageView.tintColor = .systemYellow
        default:
            assertionFailure("Unexpected notification type for MultiNotificationViewModel: \(viewModel.type)")
            typeLabel.text = nil
            iconImageView.tintColor = nil
        }

        if let statusViewModel = viewModel.statusViewModel {
            statusBodyView.viewModel = statusViewModel
            statusBodyView.isHidden = false
        } else {
            statusBodyView.isHidden = true
        }

        timeLabel.text = viewModel.time
        timeLabel.accessibilityLabel = viewModel.accessibilityTime

        iconImageView.image = UIImage(
            systemName: viewModel.type.systemImageName,
            withConfiguration: UIImage.SymbolConfiguration(scale: .medium))

        let accessibilityAttributedLabel = NSMutableAttributedString(string: "")

        if let typeText = typeLabel.attributedText {
            accessibilityAttributedLabel.appendWithSeparator(typeText)
        }

        if !statusBodyView.isHidden,
           let statusBodyAccessibilityAttributedLabel = statusBodyView.accessibilityAttributedLabel {
            accessibilityAttributedLabel.appendWithSeparator(statusBodyAccessibilityAttributedLabel)
        }

        if let accessibilityTime = viewModel.accessibilityTime {
            accessibilityAttributedLabel.appendWithSeparator(accessibilityTime)
        }

        self.accessibilityAttributedLabel = accessibilityAttributedLabel

        accessibilityCustomActions = [
            UIAccessibilityCustomAction(
                name: NSLocalizedString("notification.accessibility.view-profiles", comment: "")
            ) { [weak self] _ in
                self?.multiNotificationConfiguration.viewModel.showAccounts()
                return true
            }
        ]
    }
    // swiftlint:enable function_body_length
}
