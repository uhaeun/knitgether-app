//
//  PencilCanvasView.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import PencilKit
import SwiftUI

struct PencilCanvasView: UIViewRepresentable {
    @Binding var drawingData: Data?

    let isDrawingEnabled: Bool
    let onDrawingChanged: (Data) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .systemPink, width: 3)
        canvasView.delegate = context.coordinator
        canvasView.isUserInteractionEnabled = isDrawingEnabled

        context.coordinator.applyDrawingData(drawingData, to: canvasView)

        return canvasView
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        context.coordinator.parent = self
        canvasView.isUserInteractionEnabled = isDrawingEnabled

        if context.coordinator.lastAppliedData != drawingData {
            context.coordinator.applyDrawingData(drawingData, to: canvasView)
        }
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: PencilCanvasView
        var lastAppliedData: Data?
        private var isApplyingDrawingData = false

        init(_ parent: PencilCanvasView) {
            self.parent = parent
        }

        func applyDrawingData(_ data: Data?, to canvasView: PKCanvasView) {
            isApplyingDrawingData = true
            defer {
                isApplyingDrawingData = false
            }

            lastAppliedData = data

            guard let data else {
                canvasView.drawing = PKDrawing()
                return
            }

            do {
                canvasView.drawing = try PKDrawing(data: data)
            } catch {
                canvasView.drawing = PKDrawing()
            }
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            guard !isApplyingDrawingData else {
                return
            }

            let data = canvasView.drawing.dataRepresentation()
            lastAppliedData = data
            parent.drawingData = data
            parent.onDrawingChanged(data)
        }
    }
}
