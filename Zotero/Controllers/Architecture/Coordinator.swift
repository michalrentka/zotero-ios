//
//  Coordinator.swift
//  Zotero
//
//  Created by Michal Rentka on 10/03/2020.
//  Copyright © 2020 Corporation for Digital Scholarship. All rights reserved.
//

import UIKit
import CocoaLumberjackSwift

enum SourceView {
    case view(UIView, CGRect?)
    case item(UIBarButtonItem)
}

protocol Coordinator: AnyObject {
    var parentCoordinator: Coordinator? { get }
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController? { get }

    func start(animated: Bool)
    func childDidFinish(_ child: Coordinator)
    func share(
        item: Any,
        sourceView: SourceView,
        presenter: UIViewController?,
        userInterfaceStyle: UIUserInterfaceStyle?,
        completionWithItemsHandler: UIActivityViewController.CompletionWithItemsHandler?
    )
}

extension Coordinator {
    func childDidFinish(_ child: Coordinator) {
        if let index = self.childCoordinators.firstIndex(where: { $0 === child }) {
            self.childCoordinators.remove(at: index)
        }

        // Take navigation controller delegate back from child if needed
        if self.navigationController?.delegate === child,
           let delegate = self as? UINavigationControllerDelegate {
            self.navigationController?.delegate = delegate
        }
    }

    func share(
        item: Any,
        sourceView: SourceView,
        presenter: UIViewController? = nil,
        userInterfaceStyle: UIUserInterfaceStyle? = nil,
        completionWithItemsHandler: UIActivityViewController.CompletionWithItemsHandler? = nil
    ) {
        let controller = UIActivityViewController(activityItems: [item], applicationActivities: nil)
        if let userInterfaceStyle {
            controller.overrideUserInterfaceStyle = userInterfaceStyle
        }
        controller.modalPresentationStyle = .pageSheet
        controller.completionWithItemsHandler = completionWithItemsHandler

        switch sourceView {
        case .item(let item):
            controller.popoverPresentationController?.barButtonItem = item

        case .view(let sourceView, let sourceRect):
            controller.popoverPresentationController?.sourceView = sourceView
            if let rect = sourceRect {
                controller.popoverPresentationController?.sourceRect = rect
            }
        }

        (presenter ?? navigationController)?.present(controller, animated: true, completion: nil)
    }
}

protocol ReaderAnnotation {
    var key: String { get }
    var type: AnnotationType { get }
    var pageLabel: String { get }
    var lineWidth: CGFloat? { get }
    var color: String { get }
    var comment: String { get }
    var text: String? { get }
    var fontSize: CGFloat? { get }
    var sortIndex: String { get }
    var dateModified: Date { get }

    func editability(currentUserId: Int, library: Library) -> AnnotationEditability
}

protocol ReaderError: Error {
    var title: String { get }
    var message: String { get }
}

protocol ReaderCoordinatorDelegate: AnyObject {
    func show(error: ReaderError)
    func showToolSettings(tool: AnnotationTool, colorHex: String?, sizeValue: Float?, sender: SourceView, userInterfaceStyle: UIUserInterfaceStyle, valueChanged: @escaping (String?, Float?) -> Void)
}

protocol ReaderSidebarCoordinatorDelegate: AnyObject {
    func showTagPicker(libraryId: LibraryIdentifier, selected: Set<String>, userInterfaceStyle: UIUserInterfaceStyle?, picked: @escaping ([Tag]) -> Void)
    func showCellOptions(
        for annotation: ReaderAnnotation,
        userId: Int,
        library: Library,
        highlightFont: UIFont,
        sender: UIButton,
        userInterfaceStyle: UIUserInterfaceStyle,
        saveAction: @escaping AnnotationEditSaveAction,
        deleteAction: @escaping AnnotationEditDeleteAction
    )
    func showFilterPopup(
        from barButton: UIBarButtonItem,
        filter: AnnotationsFilter?,
        availableColors: [String],
        availableTags: [Tag],
        userInterfaceStyle: UIUserInterfaceStyle,
        completed: @escaping (AnnotationsFilter?) -> Void
    )
    func showSettings(with settings: ReaderSettings, sender: UIBarButtonItem) -> ViewModel<ReaderSettingsActionHandler>
}

protocol ReaderAnnotationsDelegate: AnyObject {
    func parseAndCacheIfNeededAttributedText(for annotation: ReaderAnnotation, with font: UIFont) -> NSAttributedString?
    func parseAndCacheIfNeededAttributedComment(for annotation: ReaderAnnotation) -> NSAttributedString?
}

protocol ReaderCoordinator: Coordinator, ReaderCoordinatorDelegate, ReaderSidebarCoordinatorDelegate {
    var controllers: Controllers { get }
}

extension ReaderCoordinator {
    func show(error: ReaderError) {
        let controller = UIAlertController(title: error.title, message: error.message, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: L10n.ok, style: .default))
        navigationController?.present(controller, animated: true)
    }

    func showToolSettings(tool: AnnotationTool, colorHex: String?, sizeValue: Float?, sender: SourceView, userInterfaceStyle: UIUserInterfaceStyle, valueChanged: @escaping (String?, Float?) -> Void) {
        DDLogInfo("ReaderCoordinator: show tool settings for \(tool)")
        let state = AnnotationToolOptionsState(tool: tool, colorHex: colorHex, size: sizeValue)
        let handler = AnnotationToolOptionsActionHandler()
        let controller = AnnotationToolOptionsViewController(viewModel: ViewModel(initialState: state, handler: handler), valueChanged: valueChanged)

        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            controller.overrideUserInterfaceStyle = userInterfaceStyle
            controller.modalPresentationStyle = .popover
            switch sender {
            case .view(let view, _):
                controller.popoverPresentationController?.sourceView = view

            case .item(let item):
                controller.popoverPresentationController?.barButtonItem = item
            }
            navigationController?.present(controller, animated: true, completion: nil)

        default:
            let navigationController = UINavigationController(rootViewController: controller)
            navigationController.modalPresentationStyle = .formSheet
            navigationController.overrideUserInterfaceStyle = userInterfaceStyle
            self.navigationController?.present(navigationController, animated: true, completion: nil)
        }
    }
}

extension ReaderCoordinator {
    func showTagPicker(libraryId: LibraryIdentifier, selected: Set<String>, userInterfaceStyle: UIUserInterfaceStyle?, picked: @escaping ([Tag]) -> Void) {
        guard let navigationController, let parentCoordinator = parentCoordinator as? DetailCoordinator else { return }
        parentCoordinator.showTagPicker(libraryId: libraryId, selected: selected, userInterfaceStyle: userInterfaceStyle, navigationController: navigationController, picked: picked)
    }

    func showCellOptions(
        for annotation: any ReaderAnnotation,
        userId: Int,
        library: Library,
        highlightFont: UIFont,
        sender: UIButton,
        userInterfaceStyle: UIUserInterfaceStyle,
        saveAction: @escaping AnnotationEditSaveAction,
        deleteAction: @escaping AnnotationEditDeleteAction
    ) {
        let navigationController = NavigationViewController()
        navigationController.overrideUserInterfaceStyle = userInterfaceStyle

        let highlightText: NSAttributedString = (self.navigationController?.viewControllers.first as? ReaderAnnotationsDelegate)?
            .parseAndCacheIfNeededAttributedText(for: annotation, with: highlightFont) ?? .init(string: "")
        let coordinator = AnnotationEditCoordinator(
            data: AnnotationEditState.Data(
                type: annotation.type,
                isEditable: annotation.editability(currentUserId: userId, library: library) == .editable,
                color: annotation.color,
                lineWidth: annotation.lineWidth ?? 0,
                pageLabel: annotation.pageLabel,
                highlightText: highlightText,
                highlightFont: highlightFont,
                fontSize: annotation.fontSize
            ),
            saveAction: saveAction,
            deleteAction: deleteAction,
            navigationController: navigationController,
            controllers: controllers
        )
        coordinator.parentCoordinator = self
        childCoordinators.append(coordinator)
        coordinator.start(animated: false)

        if UIDevice.current.userInterfaceIdiom == .pad {
            navigationController.modalPresentationStyle = .popover
            navigationController.popoverPresentationController?.sourceView = sender
            navigationController.popoverPresentationController?.permittedArrowDirections = .left
        }

        self.navigationController?.present(navigationController, animated: true, completion: nil)
    }

    func showFilterPopup(
        from barButton: UIBarButtonItem,
        filter: AnnotationsFilter?,
        availableColors: [String],
        availableTags: [Tag],
        userInterfaceStyle: UIUserInterfaceStyle,
        completed: @escaping (AnnotationsFilter?) -> Void
    ) {
        DDLogInfo("ReaderCoordinator: show annotations filter popup")

        let navigationController = NavigationViewController()
        navigationController.overrideUserInterfaceStyle = userInterfaceStyle
        let coordinator = AnnotationsFilterPopoverCoordinator(
            initialFilter: filter,
            availableColors: availableColors,
            availableTags: availableTags,
            navigationController: navigationController,
            controllers: controllers,
            completionHandler: completed
        )
        coordinator.parentCoordinator = self
        childCoordinators.append(coordinator)
        coordinator.start(animated: false)

        if UIDevice.current.userInterfaceIdiom == .pad {
            navigationController.modalPresentationStyle = .popover
            navigationController.popoverPresentationController?.barButtonItem = barButton
            navigationController.popoverPresentationController?.permittedArrowDirections = .down
        }

        self.navigationController?.present(navigationController, animated: true, completion: nil)
    }

    func showSettings(with settings: ReaderSettings, sender: UIBarButtonItem) -> ViewModel<ReaderSettingsActionHandler> {
        DDLogInfo("ReaderCoordinator: show settings")

        let state = ReaderSettingsState(settings: settings)
        let viewModel = ViewModel(initialState: state, handler: ReaderSettingsActionHandler())
        let baseController = ReaderSettingsViewController(rows: settings.rows, viewModel: viewModel)
        let controller: UIViewController
        if UIDevice.current.userInterfaceIdiom == .pad {
            controller = baseController
        } else {
            controller = UINavigationController(rootViewController: baseController)
        }
        controller.modalPresentationStyle = UIDevice.current.userInterfaceIdiom == .pad ? .popover : .formSheet
        controller.popoverPresentationController?.barButtonItem = sender
        controller.preferredContentSize = settings.preferredContentSize
        controller.overrideUserInterfaceStyle = settings.appearance.userInterfaceStyle
        navigationController?.present(controller, animated: true, completion: nil)

        return viewModel
    }
}
