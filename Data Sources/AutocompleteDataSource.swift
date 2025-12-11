// Copyright © 2021 Metabolist. All rights reserved.

import Combine
import Mastodon
import UIKit
import ViewModels

enum AutocompleteSection: Int, Hashable {
  case search
  case emoji
}

enum AutocompleteItem: Hashable {
  case account(Account)
  case tag(Tag)
  case emoji(PickerEmoji)
}

/// Data source for autocompleting hashtags, accounts, and emoji in the post composer.
final class AutocompleteDataSource: UICollectionViewDiffableDataSource<AutocompleteSection, AutocompleteItem> {
  /// Used to search tags only.
  @Published private var searchViewModel: SearchViewModel
  @Published private var accountSearchViewModel: AccountSearchViewModel
  @Published private var emojiPickerViewModel: EmojiPickerViewModel

  private let updateQueue =
    DispatchQueue(label: "com.metabolist.metatext.autocomplete-data-source.update-queue")
  private var cancellables = Set<AnyCancellable>()

  init(
    collectionView: UICollectionView,
    queryPublisher: AnyPublisher<String?, Never>,
    parentViewModel: ComposeStatusViewModel
  ) {
    searchViewModel = SearchViewModel(identityContext: parentViewModel.identityContext, .compositionAutocomplete)
    accountSearchViewModel = AccountSearchViewModel(identityContext: parentViewModel.identityContext)
    emojiPickerViewModel = EmojiPickerViewModel(identityContext: parentViewModel.identityContext, queryOnly: true)

    let registration = UICollectionView.CellRegistration<AutocompleteItemCollectionViewCell, AutocompleteItem> {
      $0.item = $2
      $0.identityContext = parentViewModel.identityContext
    }

    let emojiRegistration = UICollectionView.CellRegistration<EmojiCollectionViewCell, PickerEmoji> {
      $0.viewModel = EmojiViewModel(emoji: $2, identityContext: parentViewModel.identityContext)
    }

    super
      .init(collectionView: collectionView) {
        if case .emoji(let emoji) = $2 {
          return $0.dequeueConfiguredReusableCell(using: emojiRegistration, for: $1, item: emoji)
        } else {
          return $0.dequeueConfiguredReusableCell(using: registration, for: $1, item: $2)
        }
      }

    searchViewModel.scope = .tags

    queryPublisher
      .replaceNil(with: "")
      .removeDuplicates()
      .combineLatest($searchViewModel, $accountSearchViewModel, $emojiPickerViewModel)
      .sink(receiveValue: Self.combine(query:searchViewModel:accountSearchViewModel:emojiPickerViewModel:))
      .store(in: &cancellables)

    $searchViewModel.map(\.updates)
      .switchToLatest()
      .combineLatest(
        $accountSearchViewModel.map(\.updates).switchToLatest(),
        $emojiPickerViewModel.map(\.$emoji).switchToLatest()
      )
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in
        self?.apply(searchViewModelUpdate: $0, accountSearchViewModelUpdate: $1, emojiSections: $2)
      }
      .store(in: &cancellables)

    parentViewModel.$identityContext
      .dropFirst()
      .sink { [weak self] in
        guard let self = self else { return }

        searchViewModel = SearchViewModel(identityContext: $0, .compositionAutocomplete)
        searchViewModel.scope = .tags
        self.emojiPickerViewModel = EmojiPickerViewModel(identityContext: $0, queryOnly: true)
      }
      .store(in: &cancellables)
  }

  override func apply(
    _ snapshot: NSDiffableDataSourceSnapshot<AutocompleteSection, AutocompleteItem>,
    animatingDifferences: Bool = true,
    completion: (() -> Void)? = nil
  ) {
    updateQueue.async {
      super.apply(snapshot, animatingDifferences: animatingDifferences, completion: completion)
    }
  }
}

extension AutocompleteDataSource {
  func updateUse(emoji: PickerEmoji) {
    emojiPickerViewModel.updateUse(emoji: emoji)
  }
}

extension AutocompleteDataSource {
  fileprivate static func combine(
    query: String,
    searchViewModel: SearchViewModel,
    accountSearchViewModel: AccountSearchViewModel,
    emojiPickerViewModel: EmojiPickerViewModel
  ) {
    if query.starts(with: ":") {
      searchViewModel.query = ""
      accountSearchViewModel.query = ""
      emojiPickerViewModel.query = String(query.dropFirst())
    } else if query.starts(with: "@") {
      searchViewModel.query = ""
      accountSearchViewModel.query = String(query.dropFirst())
      emojiPickerViewModel.query = ""
    } else if query.starts(with: "#") {
      searchViewModel.query = String(query.dropFirst())
      accountSearchViewModel.query = ""
      emojiPickerViewModel.query = ""
    }
  }

  fileprivate func apply(
    searchViewModelUpdate: CollectionUpdate,
    accountSearchViewModelUpdate: CollectionUpdate,
    emojiSections: [PickerEmoji.Category: [PickerEmoji]]
  ) {
    var newSnapshot = NSDiffableDataSourceSnapshot<AutocompleteSection, AutocompleteItem>()
    let tagItems: [AutocompleteItem] = searchViewModelUpdate.sections.map(\.items).reduce([], +)
      .compactMap {
        switch $0 {
        case .tag(let tag):
          return .tag(tag)
        default:
          return nil
        }
      }
    let accountItems: [AutocompleteItem] = accountSearchViewModelUpdate.sections.map(\.items).reduce([], +)
      .compactMap {
        switch $0 {
        case .account(let account, _, _, _, _):
          return .account(account)
        default:
          return nil
        }
      }
    let emojis = emojiSections.sorted { $0.0 < $1.0 }.map(\.value).reduce([], +).map(AutocompleteItem.emoji)

    newSnapshot.appendSections([.search])

    if !tagItems.isEmpty {
      newSnapshot.appendItems(tagItems, toSection: .search)
    } else if !accountItems.isEmpty {
      newSnapshot.appendItems(accountItems, toSection: .search)
    } else if !emojis.isEmpty {
      newSnapshot.appendSections([.emoji])
      newSnapshot.appendItems(emojis, toSection: .emoji)
    }

    apply(newSnapshot, animatingDifferences: !UIAccessibility.isReduceMotionEnabled) {
      // animation causes issue with custom emoji images requiring reload
      newSnapshot.reloadItems(newSnapshot.itemIdentifiers)
      self.apply(newSnapshot, animatingDifferences: false)
    }
  }
}
