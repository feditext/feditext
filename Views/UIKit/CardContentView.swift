// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import UIKit

/// Expanded variant of `CardView` for use in explore tab.
/// Contains history display derived from `TagView`.
class CardContentView: UIView {
  private let imageView = UIImageView()
  private let titleLabel = UILabel()
  private let urlLabel = UILabel()
  private let accountsLabel = UILabel()
  private let usesLabel = UILabel()
  private let lineChartView = LineChartView()
  private let descriptionLabel = UILabel()

  init(configuration: CardContentConfiguration) {
    cardConfiguration = configuration

    super.init(frame: .zero)

    isAccessibilityElement = true
    accessibilityHint = NSLocalizedString("card.article.accessibility-hint", comment: "")

    let stackView = UIStackView()
    addSubview(stackView)
    stackView.axis = .vertical
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.isLayoutMarginsRelativeArrangement = true
    stackView.directionalLayoutMargins =
      .init(top: .defaultSpacing, leading: .defaultSpacing, bottom: .defaultSpacing, trailing: .defaultSpacing)
    stackView.spacing = .defaultSpacing

    let imageTitleStackView = UIStackView()
    stackView.addArrangedSubview(imageTitleStackView)
    imageTitleStackView.axis = .horizontal
    imageTitleStackView.alignment = .center
    imageTitleStackView.spacing = .defaultSpacing

    imageTitleStackView.addArrangedSubview(imageView)
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    imageView.layer.cornerRadius = .defaultCornerRadius

    imageTitleStackView.addArrangedSubview(titleLabel)
    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.adjustsFontForContentSizeCategory = true
    titleLabel.numberOfLines = 0

    let historyStackView = UIStackView()
    stackView.addArrangedSubview(historyStackView)
    historyStackView.axis = .horizontal
    historyStackView.spacing = .defaultSpacing

    let historyAccountsUrlStackView = UIStackView()
    historyStackView.addArrangedSubview(historyAccountsUrlStackView)
    historyAccountsUrlStackView.axis = .vertical
    historyAccountsUrlStackView.spacing = .compactSpacing

    historyAccountsUrlStackView.addArrangedSubview(urlLabel)
    urlLabel.font = .preferredFont(forTextStyle: .headline)
    urlLabel.adjustsFontForContentSizeCategory = true
    urlLabel.textColor = .secondaryLabel

    historyAccountsUrlStackView.addArrangedSubview(accountsLabel)
    accountsLabel.adjustsFontForContentSizeCategory = true
    accountsLabel.font = .preferredFont(forTextStyle: .subheadline)
    accountsLabel.textColor = .secondaryLabel

    historyStackView.addArrangedSubview(UIView())

    historyStackView.addArrangedSubview(usesLabel)
    usesLabel.adjustsFontForContentSizeCategory = true
    usesLabel.font = .preferredFont(forTextStyle: .largeTitle)
    usesLabel.setContentHuggingPriority(.required, for: .vertical)

    historyStackView.addArrangedSubview(lineChartView)

    stackView.addArrangedSubview(descriptionLabel)
    descriptionLabel.font = .preferredFont(forTextStyle: .subheadline)
    descriptionLabel.adjustsFontForContentSizeCategory = true
    descriptionLabel.numberOfLines = 0

    NSLayoutConstraint.activate([
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
      stackView.topAnchor.constraint(equalTo: topAnchor),
      stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
      imageView.widthAnchor.constraint(equalToConstant: .avatarDimension),
      imageView.heightAnchor.constraint(equalToConstant: .avatarDimension),
      lineChartView.heightAnchor.constraint(equalTo: usesLabel.heightAnchor),
      lineChartView.widthAnchor.constraint(equalTo: lineChartView.heightAnchor, multiplier: 16 / 9),
    ])

    // swiftlint:disable:next inert_defer
    defer {
      cardConfiguration = configuration
    }
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private var cardConfiguration: CardContentConfiguration {
    didSet {
      let viewModel = cardConfiguration.viewModel
      var accessibilityLabel: String

      titleLabel.text = viewModel.title
      accessibilityLabel = viewModel.title

      if let displayHost = viewModel.displayHost {
        urlLabel.text = viewModel.displayHost
        accessibilityLabel.appendWithSeparator(displayHost)
      } else {
        urlLabel.text = nil
      }

      imageView.sd_setImage(with: viewModel.imageURL)

      if let accountsText = viewModel.accountsText {
        accountsLabel.text = accountsText
        accountsLabel.isHidden = false
        if let accessibilityAccountsText = viewModel.accessibilityAccountsText {
          accessibilityLabel.appendWithSeparator(accessibilityAccountsText)
        }
      } else {
        accountsLabel.isHidden = true
      }

      if let recentUsesText = viewModel.recentUsesText {
        usesLabel.text = recentUsesText
        usesLabel.isHidden = false
        if let accessibilityRecentUsesText = viewModel.accessibilityRecentUsesText {
          accessibilityLabel.appendWithSeparator(accessibilityRecentUsesText)
        }
      } else {
        usesLabel.isHidden = true
      }

      lineChartView.values = viewModel.usageHistory.reversed()
      lineChartView.isHidden = viewModel.usageHistory.isEmpty

      if !viewModel.description.isEmpty {
        descriptionLabel.text = viewModel.description
        descriptionLabel.isHidden = false
        accessibilityLabel.appendWithSeparator(viewModel.description)
      } else {
        descriptionLabel.isHidden = true
      }

      self.accessibilityLabel = accessibilityLabel
    }
  }
}

extension CardContentView: UIContentView {
  var configuration: UIContentConfiguration {
    get { cardConfiguration }
    set {
      guard let cardConfiguration = newValue as? CardContentConfiguration else { return }

      self.cardConfiguration = cardConfiguration
    }
  }
}
