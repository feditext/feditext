// Copyright © 2021 Metabolist. All rights reserved.

import UIKit

class ReactionsCollectionView: UICollectionView {
  init() {
    super.init(frame: .zero, collectionViewLayout: Self.layout())

    backgroundColor = .clear
    isScrollEnabled = false
    showsVerticalScrollIndicator = false
    showsHorizontalScrollIndicator = false
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    if bounds.size != intrinsicContentSize {
      invalidateIntrinsicContentSize()
    }
  }

  override var intrinsicContentSize: CGSize {
    CGSize(width: UIView.noIntrinsicMetric, height: max(contentSize.height, .minimumButtonDimension))
  }
}

extension ReactionsCollectionView {
  fileprivate static func layout() -> UICollectionViewLayout {
    let itemSize = NSCollectionLayoutSize(
      widthDimension: .estimated(.minimumButtonDimension),
      heightDimension: .estimated(.minimumButtonDimension)
    )
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    let groupSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1),
      heightDimension: .estimated(.minimumButtonDimension)
    )
    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

    group.interItemSpacing = .flexible(.defaultSpacing)

    let section = NSCollectionLayoutSection(group: group)

    section.interGroupSpacing = .defaultSpacing

    return UICollectionViewCompositionalLayout(section: section)
  }
}
