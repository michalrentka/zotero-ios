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

protocol ReaderError: Error {
    var title: String { get }
    var message: String { get }
}

protocol ReaderCoordinatorDelegate: AnyObject {
    func show(error: ReaderError)
    func showToolSettings(tool: AnnotationTool, colorHex: String?, sizeValue: Float?, sender: SourceView, userInterfaceStyle: UIUserInterfaceStyle, valueChanged: @escaping (String?, Float?) -> Void)
}

protocol ReaderCoordinator: Coordinator, ReaderCoordinatorDelegate {
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
