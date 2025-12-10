// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import Mastodon
import SDWebImage
import UIKit
import ViewModels

private let targetAvatarDimension: CGFloat = .avatarDimension / 2

/// Display the report info that comes with a report notification, including a subset of the target account info.
class NotificationReportView: UIView {
  private let stackView = UIStackView()
  private let targetAccountStackView = UIStackView()
  private let targetAccountAvatarImageView = SDAnimatedImageView()
  private let targetAccountDisplayNameLabel = AnimatedAttachmentLabel()
  private let targetAccountAccountLabel = UILabel()
  private let categoryStackView = UIStackView()
  private let categoryIcon = UIImageView()
  private let categoryLabel = UILabel()
  private var rules = [Rule]()
  private let ruleStackView = UIStackView()
  private let commentLabel = UILabel()

  init() {
    super.init(frame: .zero)
    initialSetup()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func initialSetup() {
    addSubview(stackView)
    stackView.axis = .vertical
    stackView.spacing = .compactSpacing
    stackView.translatesAutoresizingMaskIntoConstraints = false

    stackView.addArrangedSubview(targetAccountStackView)
    targetAccountStackView.axis = .horizontal
    targetAccountStackView.spacing = .compactSpacing

    stackView.setCustomSpacing(.defaultSpacing, after: targetAccountStackView)

    let targetAccountAvatarStackView = UIStackView()
    targetAccountStackView.addArrangedSubview(targetAccountAvatarStackView)
    targetAccountAvatarStackView.axis = .vertical

    targetAccountAvatarStackView.addArrangedSubview(UIView())

    targetAccountAvatarStackView.addArrangedSubview(targetAccountAvatarImageView)
    targetAccountAvatarImageView.layer.cornerRadius = targetAvatarDimension / 2
    targetAccountAvatarImageView.clipsToBounds = true
    targetAccountAvatarImageView.translatesAutoresizingMaskIntoConstraints = false

    targetAccountAvatarStackView.addArrangedSubview(UIView())

    let targetAccountNameStackView = UIStackView()
    targetAccountStackView.addArrangedSubview(targetAccountNameStackView)
    targetAccountNameStackView.axis = .vertical
    targetAccountNameStackView.spacing = .compactSpacing

    targetAccountNameStackView.addArrangedSubview(targetAccountDisplayNameLabel)
    targetAccountDisplayNameLabel.numberOfLines = 0
    targetAccountDisplayNameLabel.font = .preferredFont(forTextStyle: .headline)
    targetAccountDisplayNameLabel.adjustsFontForContentSizeCategory = true
    targetAccountDisplayNameLabel.textColor = .secondaryLabel

    targetAccountNameStackView.addArrangedSubview(targetAccountAccountLabel)
    targetAccountAccountLabel.numberOfLines = 0
    targetAccountAccountLabel.font = .preferredFont(forTextStyle: .subheadline)
    targetAccountAccountLabel.adjustsFontForContentSizeCategory = true
    targetAccountAccountLabel.textColor = .secondaryLabel

    stackView.addArrangedSubview(categoryStackView)
    categoryStackView.axis = .horizontal
    categoryStackView.spacing = .compactSpacing

    categoryStackView.addArrangedSubview(categoryIcon)
    categoryIcon.tintColor = .systemOrange
    categoryIcon.adjustsImageSizeForAccessibilityContentSizeCategory = true
    categoryIcon.setContentHuggingPriority(.required, for: .horizontal)
    categoryIcon.setContentCompressionResistancePriority(.required, for: .horizontal)

    categoryStackView.addArrangedSubview(categoryLabel)
    categoryLabel.font = .preferredFont(forTextStyle: .headline)
    categoryLabel.adjustsFontForContentSizeCategory = true
    categoryLabel.textColor = .secondaryLabel

    stackView.addArrangedSubview(ruleStackView)
    ruleStackView.axis = .vertical
    ruleStackView.spacing = .compactSpacing

    stackView.setCustomSpacing(.defaultSpacing, after: ruleStackView)

    stackView.addArrangedSubview(commentLabel)
    commentLabel.numberOfLines = 0
    commentLabel.font = .preferredFont(forTextStyle: .subheadline)
    commentLabel.adjustsFontForContentSizeCategory = true
    commentLabel.textColor = .secondaryLabel

    NSLayoutConstraint.activate([
      targetAccountAvatarImageView.widthAnchor.constraint(equalToConstant: targetAvatarDimension),
      targetAccountAvatarImageView.heightAnchor.constraint(equalToConstant: targetAvatarDimension),
      targetAccountAvatarImageView.centerYAnchor.constraint(equalTo: targetAccountNameStackView.centerYAnchor),
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
      stackView.topAnchor.constraint(equalTo: topAnchor),
      stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }

  public static func estimatedHeight(width: CGFloat, account: Account, comment: String, rules: [Rule]) -> CGFloat {
    let nameWidth = width - .compactSpacing - targetAvatarDimension

    let nameHeight =
      account.displayName.height(width: nameWidth, font: .preferredFont(forTextStyle: .headline))
      + .compactSpacing
      + account.displayName.height(width: nameWidth, font: .preferredFont(forTextStyle: .subheadline))

    let commentHeight =
      comment.isEmpty
      ? 0
      : comment.height(width: width, font: .preferredFont(forTextStyle: .subheadline))
        + .compactSpacing

    return max(nameHeight, targetAvatarDimension)
      + .compactSpacing
      + UIFont.preferredFont(forTextStyle: .headline).lineHeight
      + commentHeight
      + .compactSpacing
      + CGFloat(rules.count)
      * (UIFont.preferredFont(forTextStyle: .subheadline).lineHeight
        + .compactSpacing)
  }

  public var viewModel: NotificationReportViewModel? {
    didSet {
      guard let viewModel = viewModel else {
        return
      }

      let accessibilityAttributedLabel = NSMutableAttributedString(string: "")

      let identityContext = viewModel.identityContext
      let targetAccount = viewModel.report.targetAccount
      let displayName = targetAccount.displayName

      let avatarUrl =
        identityContext.appPreferences.animateAvatars == .everywhere
        ? targetAccount.avatar.url
        : targetAccount.unifiedAvatarStatic.url
      targetAccountAvatarImageView.sd_setImage(with: avatarUrl)

      targetAccountDisplayNameLabel.isHidden = displayName.isEmpty
      if !displayName.isEmpty {
        let mutableDisplayName = NSMutableAttributedString(string: displayName)
        mutableDisplayName.insert(
          emojis: targetAccount.emojis,
          view: targetAccountDisplayNameLabel,
          identityContext: identityContext
        )
        mutableDisplayName.resizeAttachments(toLineHeight: targetAccountDisplayNameLabel.font.lineHeight)
        targetAccountDisplayNameLabel.attributedText = mutableDisplayName

        accessibilityAttributedLabel.appendWithSeparator(displayName)
      }

      targetAccountAccountLabel.text = "@".appending(targetAccount.acct)
      accessibilityAttributedLabel.appendWithSeparator("@".appending(targetAccount.acct))

      let category = viewModel.report.category
      categoryIcon.image = .init(systemName: category.systemImageName)
      categoryLabel.text = category.title
      accessibilityAttributedLabel.appendWithSeparator(NSLocalizedString("report.category", comment: ""))
      accessibilityAttributedLabel.appendWithSeparator(category.title)

      if rules != viewModel.rules {
        // We guard these view changes because the view model seems to be assigned to many times during
        // the animation when a notification is tapped, causing flashes of wrong colors or out of place views.
        rules = viewModel.rules

        for subview in ruleStackView.arrangedSubviews {
          subview.removeFromSuperview()
        }

        for rule in viewModel.rules {
          let ruleHStackView = UIStackView()
          ruleStackView.addArrangedSubview(ruleHStackView)
          ruleHStackView.axis = .horizontal
          ruleHStackView.spacing = .compactSpacing

          let ruleIcon = UIImageView(
            image: .init(
              systemName: "xmark.octagon.fill",
              withConfiguration: UIImage.SymbolConfiguration(scale: .small)
            )
          )
          ruleHStackView.addArrangedSubview(ruleIcon)
          ruleIcon.tintColor = .systemOrange
          ruleIcon.adjustsImageSizeForAccessibilityContentSizeCategory = true

          let ruleLabel = UILabel()
          ruleHStackView.addArrangedSubview(ruleLabel)
          // Intentionally left defaulted to one line because some rules are llllooooonnggg.
          ruleLabel.font = .preferredFont(forTextStyle: .subheadline)
          ruleLabel.adjustsFontForContentSizeCategory = true
          ruleLabel.textColor = .secondaryLabel
          ruleLabel.text = rule.text
          // Also intentionally left out of accessibility label for the same reason.
        }
        ruleStackView.isHidden = viewModel.rules.isEmpty
      }

      let comment = viewModel.report.comment
      commentLabel.isHidden = comment.isEmpty
      commentLabel.text = comment
      if !comment.isEmpty {
        accessibilityAttributedLabel.appendWithSeparator(comment)
      }

      self.accessibilityAttributedLabel = accessibilityAttributedLabel
    }
  }
}
