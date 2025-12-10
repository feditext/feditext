// Copyright © 2023 Vyr Cossont. All rights reserved.

import Mastodon
import UIKit
import ViewModels

/// Show emoji reactions for a status.
///
/// This extends ``ReactionsCollectionView`` directly because nesting it inside a ``UIView`` breaks ``StatusView``
/// layout for currently uncomprehended reasons. It's leaky and I don't like it, but it works for now.
///
/// - See: ``AnnouncementView``
final class StatusReactionsView: ReactionsCollectionView {
  private let addReactionViewTag = UUID().hashValue

  public var viewModel: StatusViewModel? {
    didSet {
      guard let viewModel = viewModel else { return }

      var snapshot = NSDiffableDataSourceSnapshot<Int, ReactionItem>()

      snapshot.appendSections([0])
      snapshot.appendItems(
        viewModel.reactions.map(ReactionItem.reaction(reaction:)),
        toSection: 0
      )
      if viewModel.canEditReactions && viewModel.canAddMoreReactions {
        snapshot.appendItems([.addReaction], toSection: 0)
      }

      if snapshot.itemIdentifiers != reactionDataSource.snapshot().itemIdentifiers {
        reactionDataSource.apply(snapshot, animatingDifferences: false)
      }
    }
  }

  override init() {
    super.init()

    delegate = self
    dataSource = reactionDataSource
  }

  @available(*, unavailable)
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private lazy var reactionDataSource: UICollectionViewDiffableDataSource<Int, ReactionItem> = {
    let cellRegistration = UICollectionView.CellRegistration<ReactionCollectionViewCell, ReactionItem> { [weak self] in
      guard let self = self, let viewModel = self.viewModel else { return }

      switch $2 {
      case .reaction(let reaction):
        $0.viewModel = ReactionViewModel(
          reaction: reaction,
          emojis: viewModel.contentEmojis,
          identityContext: viewModel.identityContext
        )
        $0.tag = 0

      case .addReaction:
        $0.viewModel = nil
        $0.tag = self.addReactionViewTag
      }
    }

    let dataSource = UICollectionViewDiffableDataSource<Int, ReactionItem>(collectionView: self) {
      $0.dequeueConfiguredReusableCell(using: cellRegistration, for: $1, item: $2)
    }

    return dataSource
  }()
}

extension StatusReactionsView: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    collectionView.deselectItem(at: indexPath, animated: true)

    guard let reactionItem = reactionDataSource.itemIdentifier(for: indexPath),
      let viewModel = viewModel,
      viewModel.canEditReactions
    else { return }

    switch reactionItem {
    case .reaction(let reaction):
      if reaction.me {
        viewModel.removeReaction(name: reaction.name)
      } else {
        viewModel.addReaction(name: reaction.name)
      }

    case .addReaction:
      viewModel.presentEmojiPicker(sourceViewTag: addReactionViewTag)
    }

    UISelectionFeedbackGenerator().selectionChanged()
  }
}

enum ReactionItem: Hashable {
  case reaction(reaction: Reaction)
  case addReaction
}
