//
//  PDFKitView.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import PDFKit
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct PDFKitView: UIViewRepresentable {
    let url: URL
    let highlightTerms: [String]
    /// 보던 페이지를 기억할 키. 프로젝트마다 다른 값을 준다.
    let pageMemoryKey: String?

    init(url: URL, highlightTerms: [String] = [], pageMemoryKey: String? = nil) {
        self.url = url
        self.highlightTerms = highlightTerms
        self.pageMemoryKey = pageMemoryKey
    }

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.document = PDFDocument(url: url)
        applyHighlights(to: pdfView, coordinator: context.coordinator)
        context.coordinator.bind(pdfView, memoryKey: pageMemoryKey)
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        if pdfView.document?.documentURL != url {
            pdfView.document = PDFDocument(url: url)
            context.coordinator.restoreRememberedPage(in: pdfView)
        }

        applyHighlights(to: pdfView, coordinator: context.coordinator)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    /// 다른 탭이나 화면을 다녀오면 SwiftUI가 이 뷰를 다시 만들고, 그때마다 PDFView가
    /// 1페이지로 돌아갔다 (DEF-19). 보던 페이지를 기억했다가 되돌려 준다.
    final class Coordinator {
        var highlightSignature = ""
        private var memoryKey: String?
        private var observer: NSObjectProtocol?

        deinit {
            if let observer {
                NotificationCenter.default.removeObserver(observer)
            }
        }

        func bind(_ pdfView: PDFView, memoryKey: String?) {
            self.memoryKey = memoryKey
            restoreRememberedPage(in: pdfView)

            guard memoryKey != nil else {
                return
            }

            observer = NotificationCenter.default.addObserver(
                forName: .PDFViewPageChanged,
                object: pdfView,
                queue: .main
            ) { [weak self, weak pdfView] _ in
                guard let self, let pdfView else {
                    return
                }
                self.rememberCurrentPage(of: pdfView)
            }
        }

        func restoreRememberedPage(in pdfView: PDFView) {
            guard
                let memoryKey,
                let document = pdfView.document,
                let index = UserDefaults.standard.object(forKey: memoryKey) as? Int,
                index > 0,
                index < document.pageCount,
                let page = document.page(at: index)
            else {
                return
            }

            DispatchQueue.main.async {
                pdfView.go(to: page)
            }
        }

        private func rememberCurrentPage(of pdfView: PDFView) {
            guard
                let memoryKey,
                let document = pdfView.document,
                let current = pdfView.currentPage
            else {
                return
            }

            UserDefaults.standard.set(document.index(for: current), forKey: memoryKey)
        }
    }

    private func applyHighlights(to pdfView: PDFView, coordinator: Coordinator) {
        guard let document = pdfView.document else {
            return
        }

        let terms = normalizedHighlightTerms()
        let signature = url.absoluteString + "|" + terms.joined(separator: ",")
        guard coordinator.highlightSignature != signature else {
            return
        }

        removeSkillHighlights(from: document)

        for term in terms {
            let selections = document.findString(term, withOptions: [.caseInsensitive])
            for selection in selections {
                for page in selection.pages {
                    let bounds = selection.bounds(for: page).insetBy(dx: -1, dy: -1)
                    guard bounds.width > 0, bounds.height > 0 else {
                        continue
                    }

                    let annotation = PDFAnnotation(
                        bounds: bounds,
                        forType: .highlight,
                        withProperties: nil
                    )
                    annotation.contents = Self.highlightMarker
#if canImport(UIKit)
                    annotation.color = UIColor.systemYellow.withAlphaComponent(0.36)
#endif
                    page.addAnnotation(annotation)
                }
            }
        }

        coordinator.highlightSignature = signature
    }

    private func normalizedHighlightTerms() -> [String] {
        var seenTerms: Set<String> = []
        var terms: [String] = []

        for term in highlightTerms {
            let normalizedTerm = term.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            guard !normalizedTerm.isEmpty, !seenTerms.contains(normalizedTerm) else {
                continue
            }

            seenTerms.insert(normalizedTerm)
            terms.append(normalizedTerm)
        }

        return terms
    }

    private func removeSkillHighlights(from document: PDFDocument) {
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else {
                continue
            }

            for annotation in page.annotations where annotation.contents == Self.highlightMarker {
                page.removeAnnotation(annotation)
            }
        }
    }

    private static let highlightMarker = "KnitGetherSkillHighlight"
}
