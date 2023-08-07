// Copyright © 2021 Metabolist. All rights reserved.

import SDWebImage
import UIKit
import ViewModels

final class ReactionView: UIView {
    private let nameLabel = UILabel()
    private let imageView = SDAnimatedImageView()
    private let countLabel = UILabel()
    private var reactionConfiguration: ReactionContentConfiguration

    init(configuration: ReactionContentConfiguration) {
        reactionConfiguration = configuration

        super.init(frame: .zero)

        initialSetup()
        applyReactionConfiguration()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ReactionView: UIContentView {
    var configuration: UIContentConfiguration {
        get { reactionConfiguration }
        set {
            guard let reactionConfiguration = newValue as? ReactionContentConfiguration else {
                return
            }

            self.reactionConfiguration = reactionConfiguration

            applyReactionConfiguration()
        }
    }
}

private extension ReactionView {
    static let meBackgroundColor = UIColor.tintColor.withAlphaComponent(0.5)
    static let backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.5)
    func initialSetup() {
        layer.cornerRadius = .defaultCornerRadius

        let stackView = UIStackView()

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = .defaultSpacing

        stackView.addArrangedSubview(imageView)
        imageView.contentMode = .scaleAspectFit

        stackView.addArrangedSubview(nameLabel)
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.textAlignment = .center
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.font = .preferredFont(forTextStyle: .body)

        stackView.addArrangedSubview(countLabel)
        countLabel.adjustsFontForContentSizeCategory = true
        countLabel.font = .preferredFont(forTextStyle: .headline)
        countLabel.textColor = .tintColor

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            imageView.widthAnchor.constraint(equalToConstant: .minimumButtonDimension / 2),
            imageView.heightAnchor.constraint(equalToConstant: .minimumButtonDimension / 2),
            nameLabel.widthAnchor.constraint(equalToConstant: .minimumButtonDimension / 2),
            nameLabel.heightAnchor.constraint(equalToConstant: .minimumButtonDimension / 2)
        ])

        isAccessibilityElement = true
    }

    func applyReactionConfiguration() {
        if let viewModel = reactionConfiguration.viewModel {
            backgroundColor = viewModel.me ? Self.meBackgroundColor : Self.backgroundColor

            nameLabel.text = viewModel.name
            nameLabel.isHidden = viewModel.url != nil

            imageView.sd_setImage(with: viewModel.url)
            imageView.isHidden = viewModel.url == nil

            countLabel.text = String(viewModel.count)
            countLabel.isHidden = false

            accessibilityLabel = viewModel.name.appendingWithSeparator(String(viewModel.count))
        } else {
            // This is the add reaction button, not a reaction.
            backgroundColor = Self.backgroundColor

            nameLabel.text = nil
            nameLabel.isHidden = true

            imageView.image = .init(
                systemName: "plus",
                withConfiguration: UIImage.SymbolConfiguration(scale: .large)
            )
            imageView.isHidden = false

            countLabel.text = nil
            countLabel.isHidden = true

            accessibilityLabel = NSLocalizedString("announcement.insert-emoji", comment: "")
        }
    }
}
