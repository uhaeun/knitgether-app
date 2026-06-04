//
//  PDFKitView.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import PDFKit
import SwiftUI

struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.document = PDFDocument(url: url)
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        guard pdfView.document?.documentURL != url else {
            return
        }

        pdfView.document = PDFDocument(url: url)
    }
}
