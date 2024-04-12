// Copyright © 2021 Metabolist. All rights reserved.

import Mastodon
import UIKit
import ViewModels

/// Show an announcment with emoji reactions.
/// - See: ``StatusReactionsView`` (derived from this)
final class AnnouncementView: UIView {
    private let contentTextView = TouchFallthroughTextView()
    private let reactionsCollectionView = ReactionsCollectionView()
    private var announcementConfiguration: AnnouncementContentConfiguration
    private let addReactionViewTag = UUID().hashValue

    init(configuration: AnnouncementContentConfiguration) {
        announcementConfiguration = configuration

        super.init(frame: .zero)

        initialSetup()
        applyAnnouncementConfiguration()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var dataSource: UICollectionViewDiffableDataSource<Int, ReactionItem> = {
        let cellRegistration = UICollectionView.CellRegistration
        <ReactionCollectionViewCell, ReactionItem> { [weak self] in
            guard let self = self else { return }

            switch $2 {
            case let .reaction(reaction):
                $0.viewModel = ReactionViewModel(
                    reaction: reaction,
                    emojis: self.announcementConfiguration.viewModel.announcement.emojis,
                    identityContext: self.announcementConfiguration.viewModel.identityContext
                )
                $0.tag = 0

            case .addReaction:
                $0.viewModel = nil
                $0.tag = self.addReactionViewTag
            }
        }

        let dataSource = UICollectionViewDiffableDataSource
        <Int, ReactionItem>(collectionView: reactionsCollectionView) {
            $0.dequeueConfiguredReusableCell(using: cellRegistration, for: $1, item: $2)
        }

        return dataSource
    }()
}

extension AnnouncementView {
    static func estimatedHeight(width: CGFloat, announcement: Announcement) -> CGFloat {
        UITableView.automaticDimension
    }

    func dismissIfUnread() {
        announcementConfiguration.viewModel.dismissIfUnread()
    }
}

extension AnnouncementView: UIContentView {
    var configuration: UIContentConfiguration {
        get { announcementConfiguration }
        set {
            guard let announcementConfiguration = newValue as? AnnouncementContentConfiguration else { return }

            self.announcementConfiguration = announcementConfiguration

            applyAnnouncementConfiguration()
        }
    }
}

extension AnnouncementView: UITextViewDelegate {
    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction) -> Bool {
        switch interaction {
        case .invokeDefaultAction:
            announcementConfiguration.viewModel.urlSelected(URL)
            return false
        case .preview: return false
        case .presentActions: return false
        @unknown default: return false
        }
    }
}

extension AnnouncementView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        guard let reactionItem = dataSource.itemIdentifier(for: indexPath) else { return }

        switch reactionItem {
        case let .reaction(reaction):
            if reaction.me {
                announcementConfiguration.viewModel.removeReaction(name: reaction.name)
            } else {
                announcementConfiguration.viewModel.addReaction(name: reaction.name)
            }

        case .addReaction:
            announcementConfiguration.viewModel.presentEmojiPicker(sourceViewTag: addReactionViewTag)
        }

        UISelectionFeedbackGenerator().selectionChanged()
    }
}

private extension AnnouncementView {
    func initialSetup() {
        let stackView = UIStackView()

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = .defaultSpacing

        contentTextView.adjustsFontForContentSizeCategory = true
        contentTextView.backgroundColor = .clear
        contentTextView.delegate = self
        stackView.addArrangedSubview(contentTextView)

        stackView.addArrangedSubview(reactionsCollectionView)
        reactionsCollectionView.delegate = self
        reactionsCollectionView.setContentCompressionResistancePriority(.required, for: .vertical)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: readableContentGuide.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: readableContentGuide.bottomAnchor)
        ])
    }

    func applyAnnouncementConfiguration() {
        let viewModel = announcementConfiguration.viewModel
        let mutableContent = NSMutableAttributedString(viewModel.announcement.content.attrStr)
        let contentFont = UIFont.preferredFont(forTextStyle: .callout)
        let contentRange = NSRange(location: 0, length: mutableContent.length)

        mutableContent.removeAttribute(.font, range: contentRange)
        mutableContent.addAttributes(
            [.font: contentFont, .foregroundColor: UIColor.label],
            range: contentRange)
        mutableContent.insert(emojis: viewModel.announcement.emojis,
                              view: contentTextView,
                              identityContext: viewModel.identityContext)
        mutableContent.resizeAttachments(toLineHeight: contentFont.lineHeight)
        contentTextView.attributedText = mutableContent

        var snapshot = NSDiffableDataSourceSnapshot<Int, ReactionItem>()

        snapshot.appendSections([0])
        snapshot.appendItems(
            viewModel.announcement.reactions.map(ReactionItem.reaction(reaction:)),
            toSection: 0
        )
        snapshot.appendItems([.addReaction], toSection: 0)

        if snapshot.itemIdentifiers != dataSource.snapshot().itemIdentifiers {
            dataSource.apply(snapshot, animatingDifferences: false) {
                if self.contentTextView.frame.size == .zero
                    || self.contentTextView.contentSize.height < self.contentTextView.frame.height {
                    viewModel.reload()
                }
            }
        }
    }
}
