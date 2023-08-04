// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Mastodon
import UIKit
import ViewModels

// TODO: (Vyr) generalize this to handle more than 4 attachments
final class AttachmentsView: UIView {
    private let containerStackView = UIStackView()
    private let leftStackView = UIStackView()
    private let rightStackView = UIStackView()
    private let attachmentViews = [
        AttachmentView(),
        AttachmentView(),
        AttachmentView(),
        AttachmentView()
    ]
    private let curtain = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    private let curtainButton = UIButton(type: .system)
    private let hideButtonBackground = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    private let hideButton = UIButton()
    private var aspectRatioConstraint: NSLayoutConstraint?
    private var cancellables = Set<AnyCancellable>()

    /// If we have fewer than 4 attachments, the first one should be displayed in its own stack
    /// to give it as much space as possible. Left to right top to bottom otherwise.
    /// Lower indexes are in the left stack.
    private let viewIndexPermutations = [
        [],
        [0],
        [0, 2],
        [0, 2, 3],
        [0, 2, 1, 3]
    ]

    var viewModel: AttachmentsRenderingViewModel? {
        didSet {
            guard let viewModel = viewModel else {
                for attachmentView in self.attachmentViews {
                    attachmentView.parentViewModel = nil
                    attachmentView.viewModel = nil
                    attachmentView.isHidden_stackViewSafe = true
                }
                return
            }

            // TODO: (Vyr) attachments: remove temporary restriction to 4 attachments
            let attachmentViewModels = viewModel.attachmentViewModels.prefix(4)

            rightStackView.isHidden = attachmentViewModels.count == 1

            let viewIndexPermutation = viewIndexPermutations[attachmentViewModels.count]
            var unusedViewIndexes = Set(0..<attachmentViews.count)
            for (viewModelIndex, attachmentViewModel) in attachmentViewModels.enumerated() {
                let viewIndex = viewIndexPermutation[viewModelIndex]
                unusedViewIndexes.remove(viewIndex)

                let attachmentView = attachmentViews[viewIndex]
                attachmentView.parentViewModel = viewModel
                attachmentView.viewModel = attachmentViewModel
                attachmentView.isHidden_stackViewSafe = false
                attachmentView.removeButton.isHidden = !viewModel.canRemoveAttachments
                attachmentView.isAccessibilityElement = !viewModel.canRemoveAttachments
            }
            for viewIndex in unusedViewIndexes {
                let attachmentView = attachmentViews[viewIndex]
                attachmentView.parentViewModel = viewModel
                attachmentView.viewModel = nil
                attachmentView.isHidden_stackViewSafe = true
            }

            let newAspectRatio: CGFloat

            if attachmentViewModels.count == 1,
               let aspectRatio = attachmentViewModels.first?.attachment.aspectRatio {
                newAspectRatio = max(CGFloat(aspectRatio), 16 / 9)
            } else {
                newAspectRatio = 16 / 9
            }

            aspectRatioConstraint?.isActive = false
            aspectRatioConstraint = widthAnchor.constraint(equalTo: heightAnchor, multiplier: newAspectRatio)
            aspectRatioConstraint?.priority = .justBelowMax
            aspectRatioConstraint?.isActive = true

            curtain.isHidden = viewModel.shouldShowAttachments
            curtainButton.setTitle(
                NSLocalizedString((viewModel.sensitive)
                                    ? "attachment.sensitive-content"
                                    : "attachment.media-hidden",
                                  comment: ""),
                                   for: .normal)
            hideButtonBackground.isHidden = !viewModel.shouldShowHideAttachmentsButton

            if curtain.isHidden {
                let type: Attachment.AttachmentType

                if viewModel.attachmentViewModels
                    .allSatisfy({ $0.attachment.type == .image || $0.attachment.type == .gifv }) {
                    type = .image
                } else if attachmentViewModels.allSatisfy({ $0.attachment.type == .video }) {
                    type = .video
                } else if attachmentViewModels.allSatisfy({ $0.attachment.type == .audio }) {
                    type = .audio
                } else {
                    type = .unknown
                }

                var accessibilityLabel = type.accessibilityNames(count: attachmentViewModels.count)

                for attachmentViewModel in attachmentViewModels {
                    guard let description = attachmentViewModel.attachment.description,
                          !description.isEmpty
                    else { continue }

                    accessibilityLabel.appendWithSeparator(attachmentViewModel.attachment.type.accessibilityName)
                    accessibilityLabel.appendWithSeparator(description)
                }

                self.accessibilityLabel = accessibilityLabel
            } else {
                accessibilityLabel = curtainButton.title(for: .normal)
            }
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

extension AttachmentsView {
    static func estimatedHeight(width: CGFloat,
                                identityContext: IdentityContext,
                                status: Status,
                                configuration: CollectionItem.StatusConfiguration) -> CGFloat {
        let height: CGFloat
        if status.displayStatus.mediaAttachments.count == 1,
           let aspectRatio = status.mediaAttachments.first?.aspectRatio {
            height = width / max(CGFloat(aspectRatio), 16 / 9)
        } else {
            height = width / (16 / 9)
        }

        return height
    }
    var shouldAutoplay: Bool {
        guard !isHidden, let viewModel = viewModel, viewModel.shouldShowAttachments else { return false }

        return viewModel.attachmentViewModels.allSatisfy(\.shouldAutoplay)
    }

    var attachmentViewAccessibilityCustomActions: [UIAccessibilityCustomAction] {
        attachmentViews.compactMap { attachmentView in
            guard let accessibilityLabel = attachmentView.accessibilityLabel else { return nil }

            return UIAccessibilityCustomAction(name: accessibilityLabel) { _ in
                attachmentView.selectAttachment()

                return true
            }
        }
    }
}

private extension AttachmentsView {
    // swiftlint:disable:next function_body_length
    func initialSetup() {
        backgroundColor = .clear
        layoutMargins = .zero
        clipsToBounds = true
        layer.cornerRadius = .defaultCornerRadius
        addSubview(containerStackView)
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.distribution = .fillEqually
        containerStackView.spacing = .compactSpacing
        leftStackView.distribution = .fillEqually
        leftStackView.spacing = .compactSpacing
        leftStackView.axis = .vertical
        rightStackView.distribution = .fillEqually
        rightStackView.spacing = .compactSpacing
        rightStackView.axis = .vertical
        containerStackView.addArrangedSubview(leftStackView)
        containerStackView.addArrangedSubview(rightStackView)

        let toggleShowAttachmentsAction = UIAction { [weak self] _ in
            self?.viewModel?.toggleShowAttachments()
        }

        addSubview(hideButtonBackground)
        hideButtonBackground.translatesAutoresizingMaskIntoConstraints = false
        hideButtonBackground.clipsToBounds = true
        hideButtonBackground.layer.cornerRadius = .defaultCornerRadius

        hideButton.addAction(toggleShowAttachmentsAction, for: .touchUpInside)
        hideButtonBackground.contentView.addSubview(hideButton)
        hideButton.translatesAutoresizingMaskIntoConstraints = false
        hideButton.setImage(
            UIImage(systemName: "eye.slash", withConfiguration: UIImage.SymbolConfiguration(scale: .medium)),
            for: .normal)
        addSubview(curtain)
        curtain.translatesAutoresizingMaskIntoConstraints = false
        curtain.contentView.addSubview(curtainButton)

        curtainButton.addAction(toggleShowAttachmentsAction, for: .touchUpInside)
        curtainButton.translatesAutoresizingMaskIntoConstraints = false
        curtainButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        curtainButton.titleLabel?.adjustsFontForContentSizeCategory = true

        let split = Int((Double(attachmentViews.count) / 2).rounded(.up))
        for attachmentView in attachmentViews.prefix(split) {
            leftStackView.addArrangedSubview(attachmentView)
        }
        for attachmentView in attachmentViews.suffix(split) {
            rightStackView.addArrangedSubview(attachmentView)
        }

        NSLayoutConstraint.activate([
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerStackView.topAnchor.constraint(equalTo: topAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            hideButtonBackground.topAnchor.constraint(equalTo: topAnchor, constant: .defaultSpacing),
            hideButtonBackground.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .defaultSpacing),
            hideButton.topAnchor.constraint(
                equalTo: hideButtonBackground.contentView.topAnchor,
                constant: .compactSpacing),
            hideButton.leadingAnchor.constraint(
                equalTo: hideButtonBackground.contentView.leadingAnchor,
                constant: .compactSpacing),
            hideButtonBackground.contentView.trailingAnchor.constraint(
                equalTo: hideButton.trailingAnchor,
                constant: .compactSpacing),
            hideButtonBackground.contentView.bottomAnchor.constraint(
                equalTo: hideButton.bottomAnchor,
                constant: .compactSpacing),
            curtain.topAnchor.constraint(equalTo: topAnchor),
            curtain.leadingAnchor.constraint(equalTo: leadingAnchor),
            curtain.trailingAnchor.constraint(equalTo: trailingAnchor),
            curtain.bottomAnchor.constraint(equalTo: bottomAnchor),
            curtainButton.topAnchor.constraint(equalTo: curtain.contentView.topAnchor),
            curtainButton.leadingAnchor.constraint(equalTo: curtain.contentView.leadingAnchor),
            curtainButton.trailingAnchor.constraint(equalTo: curtain.contentView.trailingAnchor),
            curtainButton.bottomAnchor.constraint(equalTo: curtain.contentView.bottomAnchor)
        ])
    }
}
