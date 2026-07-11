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

    init(url: URL, highlightTerms: [String] = []) {
        self.url = url
        self.highlightTerms = highlightTerms
    }

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.document = PDFDocument(url: url)
        applyHighlights(to: pdfView, coordinator: context.coordinator)
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        if pdfView.document?.documentURL != url {
            pdfView.document = PDFDocument(url: url)
        }

        applyHighlights(to: pdfView, coordinator: context.coordinator)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var highlightSignature = ""
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
