import SwiftUI

#if canImport(UIKit) && canImport(VisionKit)
import UIKit
import VisionKit

struct DocumentScannerView: UIViewControllerRepresentable {
    let onCompletion: (Result<URL, Error>) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        guard VNDocumentCameraViewController.isSupported else {
            return UIHostingController(rootView: DocumentScannerUnavailableView())
        }

        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = context.coordinator
        return scannerViewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onCompletion: onCompletion)
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        private let onCompletion: (Result<URL, Error>) -> Void

        init(onCompletion: @escaping (Result<URL, Error>) -> Void) {
            self.onCompletion = onCompletion
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            do {
                let fileURL = try ScannedDocumentPDFWriter.writePDF(from: scan)
                onCompletion(.success(fileURL))
            } catch {
                onCompletion(.failure(error))
            }

            controller.dismiss(animated: true)
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            onCompletion(.failure(error))
            controller.dismiss(animated: true)
        }
    }
}

private enum ScannedDocumentPDFWriter {
    static func writePDF(from scan: VNDocumentCameraScan) throws -> URL {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("knitgether-scan-\(UUID().uuidString)")
            .appendingPathExtension("pdf")
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))

        try renderer.writePDF(to: fileURL) { context in
            for pageIndex in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: pageIndex)
                let pageBounds = CGRect(origin: .zero, size: image.size)
                context.beginPage(withBounds: pageBounds, pageInfo: [:])
                image.draw(in: pageBounds)
            }
        }

        return fileURL
    }
}

private struct DocumentScannerUnavailableView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            EmptyStateView(
                title: "문서 스캔을 사용할 수 없어요.",
                description: "iPhone 실기기에서 카메라 권한을 허용한 뒤 다시 시도해 주세요. 시뮬레이터에서는 PDF 파일 선택을 사용할 수 있어요.",
                systemImage: "doc.viewfinder"
            )
            .padding()
            .warmScreenBackground()
            .navigationTitle("문서 스캔")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
    }
}
#endif
