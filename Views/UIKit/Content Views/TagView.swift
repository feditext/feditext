// Copyright © 2020 Metabolist. All rights reserved.

import Mastodon
import UIKit

/// Tag and optional history chart. Used in the explore tab.
final class TagView: UIView {
  private let nameLabel = UILabel()
  private let accountsLabel = UILabel()
  private let usesLabel = UILabel()
  private let lineChartView = LineChartView()
  private var lineChartConstraints = [NSLayoutConstraint]()
  private var tagConfiguration: TagContentConfiguration

  init(configuration: TagContentConfiguration) {
    tagConfiguration = configuration

    super.init(frame: .zero)

    initialSetup()
    setupAccessibility()
    applyTagConfiguration()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension TagView {
  static func estimatedHeight(width: CGFloat, tag: Tag) -> CGFloat {
    UITableView.automaticDimension
  }
}

extension TagView: UIContentView {
  var configuration: UIContentConfiguration {
    get { tagConfiguration }
    set {
      guard let tagConfiguration = newValue as? TagContentConfiguration else { return }

      self.tagConfiguration = tagConfiguration

      applyTagConfiguration()
    }
  }
}

extension TagView {
  fileprivate func initialSetup() {
    let stackView = UIStackView()

    addSubview(stackView)
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.spacing = .defaultSpacing

    let verticalStackView = UIStackView()

    stackView.addArrangedSubview(verticalStackView)
    verticalStackView.axis = .vertical
    verticalStackView.spacing = .compactSpacing

    verticalStackView.addArrangedSubview(nameLabel)
    nameLabel.adjustsFontForContentSizeCategory = true
    nameLabel.font = .preferredFont(forTextStyle: .headline)

    verticalStackView.addArrangedSubview(accountsLabel)
    accountsLabel.adjustsFontForContentSizeCategory = true
    accountsLabel.font = .preferredFont(forTextStyle: .subheadline)
    accountsLabel.textColor = .secondaryLabel

    stackView.addArrangedSubview(UIView())

    stackView.addArrangedSubview(usesLabel)
    usesLabel.adjustsFontForContentSizeCategory = true
    usesLabel.font = .preferredFont(forTextStyle: .largeTitle)

    stackView.addArrangedSubview(lineChartView)

    lineChartConstraints = [
      lineChartView.heightAnchor.constraint(equalTo: usesLabel.heightAnchor),
      lineChartView.widthAnchor.constraint(equalTo: lineChartView.heightAnchor, multiplier: 16 / 9),
    ]

    NSLayoutConstraint.activate([
      stackView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
      stackView.topAnchor.constraint(equalTo: readableContentGuide.topAnchor),
      stackView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
      stackView.bottomAnchor.constraint(equalTo: readableContentGuide.bottomAnchor),
    ])
  }

  fileprivate func applyTagConfiguration() {
    let viewModel = tagConfiguration.viewModel
    var accessibilityLabel = viewModel.name

    nameLabel.text = viewModel.name

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

    if usesLabel.isHidden || lineChartView.isHidden {
      usesLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
      NSLayoutConstraint.deactivate(lineChartConstraints)
    } else {
      usesLabel.setContentHuggingPriority(.required, for: .vertical)
      NSLayoutConstraint.activate(lineChartConstraints)
    }

    self.accessibilityLabel = accessibilityLabel

    switch viewModel.identityContext.appPreferences.statusWord {
    case .toot:
      accessibilityHint = NSLocalizedString("tag.accessibility-hint.toot", comment: "")
    case .post:
      accessibilityHint = NSLocalizedString("tag.accessibility-hint.post", comment: "")
    }
  }

  fileprivate func setupAccessibility() {
    isAccessibilityElement = true
  }
}
