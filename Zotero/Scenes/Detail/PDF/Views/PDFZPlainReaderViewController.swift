//
//  PDFZPlainReaderViewController.swift
//  Zotero
//
//  Created by Michal Rentka on 27.01.2025.
//  Copyright © 2025 Corporation for Digital Scholarship. All rights reserved.
//

import UIKit

import CocoaLumberjackSwift
import PSPDFKit

class PDFZPlainReaderViewController: UIViewController {
    private let document: Document

    private weak var label: UILabel!
    private weak var scrollView: UIScrollView!

    init(document: Document) {
        self.document = document
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        label.text = extractText()

        func extractText() -> String {
            var paragraphs = ""
            for page in 0..<document.pageCount {
                guard let parser = document.textParserForPage(at: page) else { break }
//                let sortedBlocks = parser.textBlocks.sorted {
//                    let y1 = $0.frame.origin.y
//                    let y2 = $1.frame.origin.y
//                    if abs(y1 - y2) > 1e-3 { // Compare Y coordinates with a tolerance
//                        return y1 > y2 // Top-to-bottom
//                    } else {
//                        return $0.frame.origin.x < $1.frame.origin.x // Left-to-right
//                    }
//                }
//                for paragraph in sortedBlocks {
//                    paragraphs += paragraph.content + "\n"
//                }
                paragraphs += parser.text + "\n\n"
            }
            return paragraphs
        }

        func setupUI() {
            view.backgroundColor = .white

            let scrollView = UIScrollView()
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(scrollView)
            self.scrollView = scrollView

            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textColor = .black
            label.numberOfLines = 1000
            scrollView.addSubview(label)
            self.label = label

            NSLayoutConstraint.activate([
                scrollView.frameLayoutGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
                scrollView.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 8),
                view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: scrollView.frameLayoutGuide.bottomAnchor, constant: 8),
                view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: 8),
                label.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
                label.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
                label.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
                label.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
                label.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor)
            ])
        }
    }
}
