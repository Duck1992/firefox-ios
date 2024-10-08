// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

/// Simple address toolbar implementation.
/// +-------------+------------+-----------------------+----------+
/// | navigation  | indicators | url       [ page    ] | browser  |
/// |   actions   |            |           [ actions ] | actions  |
/// +-------------+------------+-----------------------+----------+
public class BrowserAddressToolbar: UIView, AddressToolbar, ThemeApplicable, LocationViewDelegate {
    private enum UX {
        static let horizontalEdgeSpace: CGFloat = 16
        static let verticalEdgeSpace: CGFloat = 8
        static let horizontalSpace: CGFloat = 8
        static let cornerRadius: CGFloat = 8
        static let dividerWidth: CGFloat = 4
        static let borderHeight: CGFloat = 1
        static let actionSpacing: CGFloat = 0
        static let buttonSize = CGSize(width: 44, height: 44)
        static let locationHeight: CGFloat = 44
    }

    private weak var toolbarDelegate: AddressToolbarDelegate?
    private var theme: Theme?

    private lazy var toolbarContainerView: UIView = .build()
    private lazy var navigationActionStack: UIStackView = .build()

    private lazy var locationContainer: UIView = .build { view in
        view.layer.cornerRadius = UX.cornerRadius
    }

    private lazy var locationView: LocationView = .build()
    private lazy var locationDividerView: UIView = .build()

    private lazy var pageActionStack: UIStackView = .build { view in
        view.spacing = UX.actionSpacing
    }
    private lazy var browserActionStack: UIStackView = .build()
    private lazy var toolbarTopBorderView: UIView = .build()
    private lazy var toolbarBottomBorderView: UIView = .build()

    private var leadingBrowserActionConstraint: NSLayoutConstraint?
    private var leadingLocationContainerConstraint: NSLayoutConstraint?
    private var dividerWidthConstraint: NSLayoutConstraint?
    private var toolbarTopBorderHeightConstraint: NSLayoutConstraint?
    private var toolbarBottomBorderHeightConstraint: NSLayoutConstraint?
    private var leadingNavigationActionStackConstraint: NSLayoutConstraint?
    private var trailingBrowserActionStackConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configure(state: AddressToolbarState,
                          toolbarDelegate: any AddressToolbarDelegate,
                          leadingSpace: CGFloat? = nil,
                          trailingSpace: CGFloat? = nil) {
        self.toolbarDelegate = toolbarDelegate
        configure(state: state)
        updateSpacing(leading: leadingSpace, trailing: trailingSpace)
    }

    public func configure(state: AddressToolbarState) {
        updateActions(state: state)
        updateBorder(borderPosition: state.borderPosition)

        locationView.configure(state.locationViewState, delegate: self)

        setNeedsLayout()
        layoutIfNeeded()
    }

    public func setAutocompleteSuggestion(_ suggestion: String?) {
        locationView.setAutocompleteSuggestion(suggestion)
    }

    override public func becomeFirstResponder() -> Bool {
        return locationView.becomeFirstResponder()
    }

    override public func resignFirstResponder() -> Bool {
        return locationView.resignFirstResponder()
    }

    // MARK: - Private
    private func setupLayout() {
        addSubview(toolbarContainerView)
        addSubview(toolbarTopBorderView)
        addSubview(toolbarBottomBorderView)

        locationContainer.addSubview(locationView)
        locationContainer.addSubview(locationDividerView)
        locationContainer.addSubview(pageActionStack)

        toolbarContainerView.addSubview(navigationActionStack)
        toolbarContainerView.addSubview(locationContainer)
        toolbarContainerView.addSubview(browserActionStack)

        leadingLocationContainerConstraint = navigationActionStack.trailingAnchor.constraint(
            equalTo: locationContainer.leadingAnchor,
            constant: -UX.horizontalSpace)
        leadingLocationContainerConstraint?.isActive = true

        leadingBrowserActionConstraint = browserActionStack.leadingAnchor.constraint(
            equalTo: locationContainer.trailingAnchor,
            constant: UX.horizontalSpace)
        leadingBrowserActionConstraint?.isActive = true

        dividerWidthConstraint = locationDividerView.widthAnchor.constraint(equalToConstant: UX.dividerWidth)
        dividerWidthConstraint?.isActive = true

        [navigationActionStack, pageActionStack, browserActionStack].forEach(setZeroWidthConstraint)

        toolbarTopBorderHeightConstraint = toolbarTopBorderView.heightAnchor.constraint(equalToConstant: 0)
        toolbarBottomBorderHeightConstraint = toolbarBottomBorderView.heightAnchor.constraint(equalToConstant: 0)
        toolbarTopBorderHeightConstraint?.isActive = true
        toolbarBottomBorderHeightConstraint?.isActive = true

        leadingNavigationActionStackConstraint = navigationActionStack.leadingAnchor.constraint(
            equalTo: toolbarContainerView.leadingAnchor,
            constant: UX.horizontalEdgeSpace)
        leadingNavigationActionStackConstraint?.isActive = true

        trailingBrowserActionStackConstraint = browserActionStack.trailingAnchor.constraint(
            equalTo: toolbarContainerView.trailingAnchor,
            constant: -UX.horizontalEdgeSpace)
        trailingBrowserActionStackConstraint?.isActive = true

        NSLayoutConstraint.activate([
            toolbarContainerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbarContainerView.topAnchor.constraint(equalTo: toolbarTopBorderView.topAnchor,
                                                      constant: UX.verticalEdgeSpace),
            toolbarContainerView.bottomAnchor.constraint(equalTo: toolbarBottomBorderView.bottomAnchor,
                                                         constant: -UX.verticalEdgeSpace),
            toolbarContainerView.trailingAnchor.constraint(equalTo: trailingAnchor),

            toolbarTopBorderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbarTopBorderView.topAnchor.constraint(equalTo: topAnchor),
            toolbarTopBorderView.trailingAnchor.constraint(equalTo: trailingAnchor),

            toolbarBottomBorderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbarBottomBorderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            toolbarBottomBorderView.bottomAnchor.constraint(equalTo: bottomAnchor),

            navigationActionStack.topAnchor.constraint(equalTo: toolbarContainerView.topAnchor),
            navigationActionStack.bottomAnchor.constraint(equalTo: toolbarContainerView.bottomAnchor),

            locationContainer.topAnchor.constraint(equalTo: toolbarContainerView.topAnchor),
            locationContainer.bottomAnchor.constraint(equalTo: toolbarContainerView.bottomAnchor),
            locationContainer.heightAnchor.constraint(equalToConstant: UX.locationHeight),

            locationView.leadingAnchor.constraint(equalTo: locationContainer.leadingAnchor),
            locationView.topAnchor.constraint(equalTo: locationContainer.topAnchor),
            locationView.trailingAnchor.constraint(equalTo: locationDividerView.leadingAnchor),
            locationView.bottomAnchor.constraint(equalTo: locationContainer.bottomAnchor),

            locationDividerView.topAnchor.constraint(equalTo: locationContainer.topAnchor),
            locationDividerView.trailingAnchor.constraint(equalTo: pageActionStack.leadingAnchor),
            locationDividerView.bottomAnchor.constraint(equalTo: locationContainer.bottomAnchor),

            pageActionStack.topAnchor.constraint(equalTo: locationContainer.topAnchor),
            pageActionStack.trailingAnchor.constraint(equalTo: locationContainer.trailingAnchor),
            pageActionStack.bottomAnchor.constraint(equalTo: locationContainer.bottomAnchor),

            browserActionStack.topAnchor.constraint(equalTo: toolbarContainerView.topAnchor),
            browserActionStack.bottomAnchor.constraint(equalTo: toolbarContainerView.bottomAnchor),
        ])

        updateActionSpacing()

        setupAccessibility()
    }

    private func setupAccessibility() {
        addInteraction(UILargeContentViewerInteraction())
    }

    internal func updateActions(state: AddressToolbarState) {
        // Browser actions
        updateActionStack(stackView: browserActionStack, toolbarElements: state.browserActions)

        // Navigation actions
        updateActionStack(stackView: navigationActionStack, toolbarElements: state.navigationActions)

        // Page actions
        updateActionStack(stackView: pageActionStack, toolbarElements: state.pageActions)

        updateActionSpacing()
    }

    private func updateSpacing(leading: CGFloat?, trailing: CGFloat?) {
        leadingNavigationActionStackConstraint?.constant = leading ?? UX.horizontalEdgeSpace
        trailingBrowserActionStackConstraint?.constant = trailing ?? -UX.horizontalEdgeSpace
    }

    private func setZeroWidthConstraint(_ stackView: UIStackView) {
        let widthAnchor = stackView.widthAnchor.constraint(equalToConstant: 0)
        widthAnchor.isActive = true
        widthAnchor.priority = .defaultHigh
    }

    private func updateActionStack(stackView: UIStackView, toolbarElements: [ToolbarElement]) {
        stackView.removeAllArrangedViews()
        toolbarElements.forEach { toolbarElement in
            let button = toolbarElement.numberOfTabs != nil ? TabNumberButton() : ToolbarButton()
            button.configure(element: toolbarElement)
            stackView.addArrangedSubview(button)

            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: UX.buttonSize.width),
                button.heightAnchor.constraint(equalToConstant: UX.buttonSize.height),
            ])

            if let theme {
                // As we recreate the buttons we need to apply the theme for them to be displayed correctly
                button.applyTheme(theme: theme)
            }

            if toolbarElement.hasContextualHint == true {
                toolbarDelegate?.configureContextualHint(self, for: button)
            }
        }
    }

    private func updateActionSpacing() {
        // Browser action spacing
        let hasBrowserActions = !browserActionStack.arrangedSubviews.isEmpty
        leadingBrowserActionConstraint?.constant = hasBrowserActions ? UX.horizontalSpace : 0

        // Navigation action spacing
        let hasNavigationActions = !navigationActionStack.arrangedSubviews.isEmpty
        let isRegular = traitCollection.horizontalSizeClass == .regular
        leadingLocationContainerConstraint?.constant = hasNavigationActions && isRegular ? -UX.horizontalSpace : 0

        // Page action spacing
        let hasPageActions = !pageActionStack.arrangedSubviews.isEmpty
        dividerWidthConstraint?.constant = hasPageActions ? UX.dividerWidth : 0
    }

    private func updateBorder(borderPosition: AddressToolbarBorderPosition?) {
        switch borderPosition {
        case .top:
            toolbarTopBorderHeightConstraint?.constant = UX.borderHeight
            toolbarBottomBorderHeightConstraint?.constant = 0
        case .bottom:
            toolbarTopBorderHeightConstraint?.constant = 0
            toolbarBottomBorderHeightConstraint?.constant = UX.borderHeight
        default:
            toolbarTopBorderHeightConstraint?.constant = 0
            toolbarBottomBorderHeightConstraint?.constant = 0
        }
    }

    // MARK: - LocationViewDelegate
    func locationViewDidRestoreSearchTerm(_ text: String) {
        toolbarDelegate?.openSuggestions(searchTerm: text)
    }

    func locationViewDidEnterText(_ text: String) {
        toolbarDelegate?.searchSuggestions(searchTerm: text)
    }

    func locationViewDidBeginEditing(_ text: String, shouldShowSuggestions: Bool) {
        toolbarDelegate?.addressToolbarDidBeginEditing(searchTerm: text, shouldShowSuggestions: shouldShowSuggestions)
    }

    func locationViewDidSubmitText(_ text: String) {
        guard !text.isEmpty else { return }

        toolbarDelegate?.openBrowser(searchTerm: text.lowercased())
    }

    func locationViewAccessibilityActions() -> [UIAccessibilityCustomAction]? {
        toolbarDelegate?.addressToolbarAccessibilityActions()
    }

    // MARK: - ThemeApplicable
    public func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layer1
        locationContainer.backgroundColor = theme.colors.layerSearch
        locationDividerView.backgroundColor = theme.colors.layer1
        toolbarTopBorderView.backgroundColor = theme.colors.borderPrimary
        toolbarBottomBorderView.backgroundColor = theme.colors.borderPrimary
        locationView.applyTheme(theme: theme)
        self.theme = theme
    }
}
