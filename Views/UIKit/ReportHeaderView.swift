// Copyright © 2021 Metabolist. All rights reserved.

import Combine
import Mastodon
import UIKit
import ViewModels

final class ReportHeaderView: UIView {
    private let viewModel: ReportViewModel
    private let stackView = UIStackView()
    private let textView = UITextView()
    private let categoryButtonStack = UIStackView()
    private let categoryButtonConfig: UIButton.Configuration
    private var categoryButtons: [UIButton] = []
    private let rulesHintLabel = UILabel()
    /// Checkboxes for picking one or more applicable rules.
    private var ruleCheckboxes: [UIButton] = []
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: ReportViewModel) {
        self.viewModel = viewModel
        var categoryButtonConfig = UIButton.Configuration.plain()
        categoryButtonConfig.buttonSize = .small
        self.categoryButtonConfig = categoryButtonConfig

        super.init(frame: .zero)

        initialSetup()

        viewModel.$categories
            .sink { [weak self] in
                self?.update(categories: $0)
            }
            .store(in: &cancellables)

        viewModel.$rules
            .sink { [weak self] in
                self?.update(rules: $0)
            }
            .store(in: &cancellables)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updateCategoryButtonStack()
    }
}

extension ReportHeaderView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        viewModel.elements.comment = textView.text
    }
}

private extension ReportHeaderView {
    // swiftlint:disable:next function_body_length
    func initialSetup() {
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = .defaultSpacing
        stackView.alignment = .leading

        let hintLabel = UILabel()

        stackView.addArrangedSubview(hintLabel)
        hintLabel.adjustsFontForContentSizeCategory = true
        hintLabel.font = .preferredFont(forTextStyle: .subheadline)
        hintLabel.text = NSLocalizedString("report.hint", comment: "")
        hintLabel.numberOfLines = 0

        // Radio buttons for selecting a report category.
        stackView.addArrangedSubview(categoryButtonStack)
        categoryButtonStack.axis = .horizontal
        categoryButtonStack.distribution = .fillProportionally

        stackView.addArrangedSubview(rulesHintLabel)
        rulesHintLabel.adjustsFontForContentSizeCategory = true
        rulesHintLabel.font = .preferredFont(forTextStyle: .subheadline)
        rulesHintLabel.numberOfLines = 0
        rulesHintLabel.text = NSLocalizedString("report.rules.hint", comment: "")

        let textViewHintLabel = UILabel()
        stackView.addArrangedSubview(textViewHintLabel)
        textViewHintLabel.adjustsFontForContentSizeCategory = true
        textViewHintLabel.font = .preferredFont(forTextStyle: .subheadline)
        textViewHintLabel.numberOfLines = 0
        textViewHintLabel.text = NSLocalizedString("report.additional-comments.hint", comment: "")

        stackView.addArrangedSubview(textView)
        textView.adjustsFontForContentSizeCategory = true
        textView.font = .preferredFont(forTextStyle: .body)
        textView.layer.borderWidth = .hairline
        textView.layer.borderColor = UIColor.separator.cgColor
        textView.layer.cornerRadius = .defaultCornerRadius
        textView.delegate = self
        textView.accessibilityLabel = NSLocalizedString("report.additional-comments", comment: "")

        if !viewModel.isLocalAccount {
            let forwardHintLabel = UILabel()

            stackView.addArrangedSubview(forwardHintLabel)
            forwardHintLabel.adjustsFontForContentSizeCategory = true
            forwardHintLabel.font = .preferredFont(forTextStyle: .subheadline)
            forwardHintLabel.text = NSLocalizedString("report.forward.hint", comment: "")
            forwardHintLabel.numberOfLines = 0

            let switchStackView = UIStackView()

            stackView.addArrangedSubview(switchStackView)
            switchStackView.spacing = .defaultSpacing

            let switchLabel = UILabel()

            switchStackView.addArrangedSubview(switchLabel)
            switchLabel.adjustsFontForContentSizeCategory = true
            switchLabel.font = .preferredFont(forTextStyle: .headline)
            switchLabel.text = String.localizedStringWithFormat(
                NSLocalizedString("report.forward-%@", comment: ""),
                viewModel.accountHost)
            switchLabel.textAlignment = .right
            switchLabel.numberOfLines = 0

            let forwardSwitch = UISwitch()

            switchStackView.addArrangedSubview(forwardSwitch)
            forwardSwitch.setContentHuggingPriority(.required, for: .horizontal)
            forwardSwitch.setContentCompressionResistancePriority(.required, for: .horizontal)
            forwardSwitch.addAction(
                UIAction { [weak self] _ in self?.viewModel.elements.forward = forwardSwitch.isOn },
                for: .valueChanged)

            NSLayoutConstraint.activate([
                switchStackView.widthAnchor.constraint(equalTo: stackView.widthAnchor)
            ])
        }

        let selectAdditionalHintLabel = UILabel()

        stackView.addArrangedSubview(selectAdditionalHintLabel)
        selectAdditionalHintLabel.adjustsFontForContentSizeCategory = true
        selectAdditionalHintLabel.font = .preferredFont(forTextStyle: .subheadline)
        selectAdditionalHintLabel.numberOfLines = 0

        switch viewModel.identityContext.appPreferences.statusWord {
        case .toot:
            selectAdditionalHintLabel.text = NSLocalizedString("report.select-additional.hint.toot", comment: "")
        case .post:
            selectAdditionalHintLabel.text = NSLocalizedString("report.select-additional.hint.post", comment: "")
        }

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: readableContentGuide.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: readableContentGuide.bottomAnchor),
            textView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            textView.heightAnchor.constraint(equalToConstant: .minimumButtonDimension * 2)
        ])
    }

    func update(categories: [Report.Category]) {
        for categoryButton in categoryButtons {
            categoryButton.removeFromSuperview()
        }
        categoryButtons = []

        for category in categories {
            let categoryButton = UIButton(
                configuration: categoryButtonConfig,
                primaryAction: UIAction(
                    title: category.title,
                    image: .init(systemName: category.systemImageName)
                ) { [weak self] action in
                    guard let self = self,
                          let thisButton = action.sender as? UIButton else {
                        return
                    }

                    // Don't allow de-selection once a category has been picked.
                    guard thisButton.isSelected else {
                        thisButton.isSelected = true
                        return
                    }

                    // Only one radio button can be selected.
                    for button in self.categoryButtons {
                        button.isSelected = button == thisButton
                    }

                    self.viewModel.elements.category = category

                    // Rule checkboxes should show up only for the rules violation category.
                    let notViolation = category != .violation
                    if notViolation {
                        self.viewModel.elements.ruleIDs.removeAll()
                        for ruleCheckbox in self.ruleCheckboxes {
                            ruleCheckbox.isSelected = false
                            ruleCheckbox.configuration?.image = .init(systemName: "square")
                        }
                    }
                    self.rulesHintLabel.isHidden_stackViewSafe = notViolation
                    for ruleCheckbox in self.ruleCheckboxes {
                        ruleCheckbox.isHidden_stackViewSafe = notViolation
                    }

                    // Required to get correct layout after rules are shown or hidden.
                    self.superview?.setNeedsLayout()
                }
            )
            categoryButton.changesSelectionAsPrimaryAction = true
            categoryButton.isSelected = category == viewModel.elements.category
            categoryButtons.append(categoryButton)
            categoryButtonStack.addArrangedSubview(categoryButton)
        }

        updateCategoryButtonStack()
    }

    func updateCategoryButtonStack() {
        let wideScreen = traitCollection.horizontalSizeClass == .regular
        let largeType = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        let horizontal = wideScreen || !largeType
        if horizontal {
            categoryButtonStack.axis = .horizontal
            categoryButtonStack.alignment = .fill
        } else {
            categoryButtonStack.axis = .vertical
            categoryButtonStack.alignment = .leading
        }
    }

    func update(rules: [Rule]) {
        for ruleCheckbox in ruleCheckboxes {
            ruleCheckbox.removeFromSuperview()
        }
        ruleCheckboxes = []

        rulesHintLabel.isHidden_stackViewSafe = viewModel.elements.category != .violation || rules.isEmpty

        guard let rulesHintLabelIndex = stackView.arrangedSubviews.firstIndex(of: rulesHintLabel) else {
            assertionFailure("Can't find rules hint label to insert rules after")
            return
        }
        var insertionPoint = rulesHintLabelIndex + 1
        for rule in rules {
            var ruleCheckboxConfig = UIButton.Configuration.plain()
            ruleCheckboxConfig.baseBackgroundColor = .clear
            ruleCheckboxConfig.image = .init(systemName: "square")
            ruleCheckboxConfig.imagePadding = .defaultSpacing
            var attributedRule = AttributedString(stringLiteral: rule.text)
            attributedRule.font = .preferredFont(forTextStyle: .subheadline)
            attributedRule.foregroundColor = UIColor.label
            ruleCheckboxConfig.attributedTitle = attributedRule
            let ruleCheckbox = UIButton(
                configuration: ruleCheckboxConfig,
                primaryAction: UIAction { [weak self] action in
                    guard let self = self,
                          let thisCheckbox = action.sender as? UIButton else {
                        return
                    }
                    if thisCheckbox.isSelected {
                        self.viewModel.elements.ruleIDs.insert(rule.id)
                        thisCheckbox.configuration?.image = .init(systemName: "checkmark.square.fill")
                    } else {
                        self.viewModel.elements.ruleIDs.remove(rule.id)
                        thisCheckbox.configuration?.image = .init(systemName: "square")
                    }
                }
            )
            ruleCheckboxes.append(ruleCheckbox)
            stackView.insertArrangedSubview(ruleCheckbox, at: insertionPoint)
            insertionPoint += 1
            ruleCheckbox.changesSelectionAsPrimaryAction = true
            ruleCheckbox.isHidden_stackViewSafe = true
        }
    }
}
