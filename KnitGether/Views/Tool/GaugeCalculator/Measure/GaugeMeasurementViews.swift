import PhotosUI
import SwiftUI
import UIKit

struct MeasurementMethodPickerView: View {
    @ObservedObject var viewModel: GaugeMeasureViewModel
    let targetID: UUID
    let swatchID: UUID

    var body: some View {
        List {
            NavigationLink {
                ManualMeasurementView(
                    viewModel: viewModel,
                    targetID: targetID,
                    swatchID: swatchID,
                    washState: .before
                )
            } label: {
                methodRow(
                    title: "수동 측정",
                    subtitle: "자와 눈으로 잰 코/단 수를 입력합니다.",
                    systemImage: "ruler"
                )
            }
            .buttonStyle(.plain)
            .listRowStyle()
            .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeManualMethodLink)

            NavigationLink {
                Photo4ptMeasurementView(
                    viewModel: viewModel,
                    targetID: targetID,
                    swatchID: swatchID,
                    washState: .before
                )
            } label: {
                methodRow(
                    title: "사진 4점 측정",
                    subtitle: "사진에서 네 모서리를 찍어 코/단 수를 추정합니다.",
                    systemImage: "photo.badge.magnifyingglass"
                )
            }
            .buttonStyle(.plain)
            .listRowStyle()
            .accessibilityIdentifier(AppAccessibilityID.Tool.gaugePhotoMethodLink)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppTheme.Color.warmBackground)
        .navigationTitle("측정 방법")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func methodRow(title: String, subtitle: String, systemImage: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(AppTheme.Color.accent)
                .frame(width: 52, height: 52)
                .background(AppTheme.Color.accentSoft, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .appCard()
    }
}

struct ManualMeasurementView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: GaugeMeasureViewModel
    let targetID: UUID
    let swatchID: UUID
    let washState: GaugeWashState

    @State private var selectedWashState: GaugeWashState
    @State private var stitches = ""
    @State private var rows = ""
    @State private var width = ""
    @State private var height = ""

    init(
        viewModel: GaugeMeasureViewModel,
        targetID: UUID,
        swatchID: UUID,
        washState: GaugeWashState
    ) {
        self.viewModel = viewModel
        self.targetID = targetID
        self.swatchID = swatchID
        self.washState = washState
        _selectedWashState = State(initialValue: washState)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                AppFormSection(
                    title: "상태",
                    description: "세탁 전/후 중 어떤 측정값인지 선택해요.",
                    systemImage: "drop.fill",
                    tint: AppTheme.Color.accent
                ) {
                Picker("세탁 상태", selection: $selectedWashState) {
                    ForEach(GaugeWashState.allCases) { state in
                        Text(state.title).tag(state)
                    }
                }
                .pickerStyle(.segmented)
                    .padding(.vertical, 12)
                }

                AppFormSection(
                    title: "측정값",
                    description: "실제 잰 면적 안의 코 수와 단 수를 입력해요.",
                    systemImage: "ruler",
                    tint: AppTheme.Color.sage
                ) {
                    AppFormDecimalRow(title: "가로 길이(cm)", systemImage: "arrow.left.and.right", text: $width)
                        .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeMeasurementWidthField)

                    AppFormDivider()

                    AppFormDecimalRow(title: "세로 길이(cm)", systemImage: "arrow.up.and.down", text: $height)
                        .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeMeasurementHeightField)

                    AppFormDivider()

                    AppFormDecimalRow(title: "코 수", systemImage: "number", text: $stitches)
                        .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeMeasurementStitchesField)

                    AppFormDivider()

                    AppFormDecimalRow(title: "단 수", systemImage: "number", text: $rows)
                        .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeMeasurementRowsField)
                }

                if let normalized {
                    AppFormSection(
                        title: "10cm 기준",
                        systemImage: "function",
                        tint: AppTheme.Color.amber
                    ) {
                        resultRow("코 수", value: "\(formatted(normalized.stitchesPer10cm))코")
                            .padding(.vertical, 10)

                        AppFormDivider()

                        resultRow("단 수", value: "\(formatted(normalized.rowsPer10cm))단")
                            .padding(.vertical, 10)
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    AppFormErrorBanner(message: errorMessage)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 96)
        }
        .safeAreaInset(edge: .bottom) {
            AppFormSubmitBar(
                isDisabled: normalized == nil || viewModel.isSaving,
                accessibilityIdentifier: AppAccessibilityID.Tool.gaugeMeasurementSaveButton
            ) {
                Task {
                    let didSave = await viewModel.saveManualMeasurement(
                        targetID: targetID,
                        swatchID: swatchID,
                        washState: selectedWashState,
                        input: input
                    )
                    if didSave {
                        dismiss()
                    }
                }
            }
        }
        .warmScreenBackground()
        .navigationTitle("수동 측정")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("취소") {
                    dismiss()
                }
            }
        }
    }

    private var input: ManualMeasurementInput {
        ManualMeasurementInput(stitches: stitches, rows: rows, width: width, height: height)
    }

    private var normalized: ManualMeasurementInput.Normalized? {
        input.normalized
    }

    private func decimalInputRow(_ title: String, text: Binding<String>, id: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 120)
                .accessibilityIdentifier(id)
        }
    }

    private func resultRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
    }

    private func formatted(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }
}

struct GaugeManualMeasurementView: View {
    @ObservedObject var viewModel: GaugeMeasureViewModel
    let targetID: UUID
    let swatchID: UUID
    let washState: GaugeWashState

    var body: some View {
        ManualMeasurementView(
            viewModel: viewModel,
            targetID: targetID,
            swatchID: swatchID,
            washState: washState
        )
    }
}

struct Photo4ptMeasurementView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: GaugeMeasureViewModel
    let targetID: UUID
    let swatchID: UUID
    let washState: GaugeWashState

    @State private var selectedWashState: GaugeWashState
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isShowingCamera = false
    @State private var cornerPoints: [CGPoint] = []
    @State private var measuredWidth = ""
    @State private var measuredHeight = ""
    @State private var correctedStitches = ""
    @State private var correctedRows = ""
    @State private var autoResult: GaugeAutoCountResult?
    @State private var localMessage: String?

    init(
        viewModel: GaugeMeasureViewModel,
        targetID: UUID,
        swatchID: UUID,
        washState: GaugeWashState
    ) {
        self.viewModel = viewModel
        self.targetID = targetID
        self.swatchID = swatchID
        self.washState = washState
        _selectedWashState = State(initialValue: washState)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                AppFormSection(
                    title: "상태",
                    description: "세탁 전/후를 분리해 저장하면 나중에 수축률을 비교할 수 있어요.",
                    systemImage: "drop",
                    tint: AppTheme.Color.accent
                ) {
                    Picker("세탁 상태", selection: $selectedWashState) {
                        ForEach(GaugeWashState.allCases) { state in
                            Text(state.title).tag(state)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 12)
                }

                AppFormSection(
                    title: "사진",
                    description: "스와치 영역의 네 꼭짓점을 찍으면 코/단 수 초안을 계산해요.",
                    systemImage: "photo.on.rectangle",
                    tint: AppTheme.Color.slate
                ) {
                    VStack(spacing: 10) {
                        photoSourceButtons
                    }
                    .padding(.vertical, 12)

                    if let selectedImage {
                        AppFormDivider()

                        Text(pointInstructionText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 12)

                        photoSelector(image: selectedImage)
                            .frame(minHeight: 260)
                            .padding(.top, 10)

                        HStack {
                            Text("\(cornerPoints.count)/4점 선택")
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                            Spacer()

                            if !cornerPoints.isEmpty {
                                Button("마지막 점 취소") {
                                    _ = cornerPoints.popLast()
                                    autoResult = nil
                                    correctedStitches = ""
                                    correctedRows = ""
                                }
                                .font(.footnote.weight(.semibold))
                            }

                            Button("초기화") {
                                resetPhotoMeasurement()
                            }
                            .font(.footnote.weight(.semibold))
                        }
                        .padding(.top, 10)
                    }
                }

                AppFormSection(
                    title: "실제 측정 면적",
                    description: "선택한 사진 영역이 실제로 몇 cm인지 입력해요.",
                    systemImage: "ruler",
                    tint: AppTheme.Color.accent
                ) {
                    AppFormDecimalRow(title: "가로 길이(cm)", systemImage: "arrow.left.and.right", text: $measuredWidth)
                        .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeMeasurementWidthField)
                    AppFormDivider()
                    AppFormDecimalRow(title: "세로 길이(cm)", systemImage: "arrow.up.and.down", text: $measuredHeight)
                        .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeMeasurementHeightField)
                }

                Button {
                    runAutoCounter()
                } label: {
                    Label("자동 계산", systemImage: "wand.and.stars")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(
                    selectedImage == nil || cornerPoints.count != 4
                    ? AppTheme.Color.softAccent.opacity(0.45)
                    : AppTheme.Color.softAccent,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .disabled(selectedImage == nil || cornerPoints.count != 4)
                .accessibilityIdentifier(AppAccessibilityID.Tool.gaugePhotoAutoButton)

                if let autoResult {
                    AppFormSection(
                        title: "자동 제안",
                        description: "제안값을 확인한 뒤 필요하면 직접 수정해요.",
                        systemImage: "sparkles",
                        tint: AppTheme.Color.amber
                    ) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 16) {
                                metric("영역 안 코", value: formatted(autoResult.stitches))
                                metric("영역 안 단", value: formatted(autoResult.rows))
                            }

                            HStack(spacing: 6) {
                                Text(autoResult.source.displayName)
                                Text("·")
                                Text("신뢰도 \(autoResult.confidence.displayName)")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)

                            Button {
                                applyAutoResult(autoResult)
                            } label: {
                                Label("제안값 다시 적용", systemImage: "arrow.down.doc")
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.vertical, 12)
                    }

                    AppFormSection(
                        title: "확인 및 수정",
                        description: "자동 계산이 맞지 않으면 최종 코/단 수를 수정하세요.",
                        systemImage: "checklist",
                        tint: AppTheme.Color.slate
                    ) {
                        AppFormDecimalRow(title: "코 수", systemImage: "circle.grid.cross", text: $correctedStitches)
                            .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeMeasurementStitchesField)
                        AppFormDivider()
                        AppFormDecimalRow(title: "단 수", systemImage: "line.3.horizontal", text: $correctedRows)
                            .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeMeasurementRowsField)
                    }

                    MeasurementResultView(
                        methodTitle: "사진 4점 측정",
                        washState: selectedWashState,
                        measuredWidth: decimalValue(from: measuredWidth) ?? 0,
                        measuredHeight: decimalValue(from: measuredHeight) ?? 0,
                        rawStitches: decimalValue(from: correctedStitches) ?? autoResult.stitches,
                        rawRows: decimalValue(from: correctedRows) ?? autoResult.rows,
                        confidence: autoResult.confidence.displayName
                    ) {
                        guard
                            let width = decimalValue(from: measuredWidth),
                            let height = decimalValue(from: measuredHeight),
                            let stitches = decimalValue(from: correctedStitches),
                            let rows = decimalValue(from: correctedRows)
                        else {
                            localMessage = "측정 면적과 코/단 수를 입력해 주세요."
                            return false
                        }

                        let didSave = await viewModel.savePhotoMeasurement(
                            targetID: targetID,
                            swatchID: swatchID,
                            washState: selectedWashState,
                            measuredWidth: width,
                            measuredHeight: height,
                            autoResult: autoResult,
                            correctedStitches: stitches,
                            correctedRows: rows,
                            cornerCoordinates: encodedCornerPoints
                        )
                        if didSave {
                            dismiss()
                        }
                        return didSave
                    }
                }

                if let message = localMessage ?? viewModel.errorMessage {
                    AppFormErrorBanner(message: message)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .background(AppTheme.Color.warmBackground.ignoresSafeArea())
        .navigationTitle("사진 4점 측정")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedItem) { item in
            Task {
                await loadImage(from: item)
            }
        }
        .sheet(isPresented: $isShowingCamera) {
            GaugeCameraCaptureView { image in
                setImage(image)
            }
        }
    }

    @ViewBuilder
    private var photoSourceButtons: some View {
        ForEach(PhotoMeasurementSource.availableSources(), id: \.self) { source in
            switch source {
            case .photoLibrary:
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label(source.displayName, systemImage: source.icon)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier(AppAccessibilityID.Tool.gaugePhotoPicker)
            case .camera:
                Button {
                    isShowingCamera = true
                } label: {
                    Label(source.displayName, systemImage: source.icon)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func photoSelector(image: UIImage) -> some View {
        GeometryReader { proxy in
            ZStack {
                let imageFrame = scaledImageFrame(for: image, in: proxy.size)

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                guard cornerPoints.count < 4 else {
                                    return
                                }

                                let normalized = normalizedPoint(value.location, in: imageFrame)
                                cornerPoints.append(normalized)
                                autoResult = nil
                                correctedStitches = ""
                                correctedRows = ""
                            }
                    )

                if cornerPoints.count >= 2 {
                    GaugeMeasurementQuadOverlay(points: cornerPoints, imageFrame: imageFrame)
                }

                ForEach(Array(cornerPoints.enumerated()), id: \.offset) { index, point in
                    GaugeMeasurementPointMarker(index: index + 1)
                        .position(denormalizedPoint(point, in: imageFrame))
                }
            }
        }
    }

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item else {
            selectedImage = nil
            cornerPoints = []
            return
        }

        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            localMessage = "사진을 불러오지 못했어요."
            return
        }

        selectedImage = image
        resetPhotoMeasurement()
        localMessage = nil
    }

    private func runAutoCounter() {
        guard let selectedImage else {
            return
        }

        guard let result = GaugeAutoCounter().estimateCounts(in: selectedImage, cornerPoints: cornerPoints) else {
            localMessage = "사진에서 코/단 수를 추정하지 못했어요. 네 점을 다시 선택해 주세요."
            return
        }

        autoResult = result
        applyAutoResult(result)
        localMessage = nil
    }

    private var pointInstructionText: String {
        let messages = [
            "왼쪽 위 꼭짓점을 선택해 주세요.",
            "오른쪽 위 꼭짓점을 선택해 주세요.",
            "오른쪽 아래 꼭짓점을 선택해 주세요.",
            "왼쪽 아래 꼭짓점을 선택해 주세요.",
            "영역 지정이 끝났어요. 자동 계산 후 제안값을 확인하세요."
        ]
        return messages[min(cornerPoints.count, 4)]
    }

    private func setImage(_ image: UIImage) {
        selectedImage = image
        selectedItem = nil
        resetPhotoMeasurement()
        localMessage = nil
    }

    private func resetPhotoMeasurement() {
        cornerPoints = []
        autoResult = nil
        correctedStitches = ""
        correctedRows = ""
    }

    private func applyAutoResult(_ result: GaugeAutoCountResult) {
        correctedStitches = formatted(result.stitches)
        correctedRows = formatted(result.rows)
    }

    private func metric(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(AppTheme.Color.accent)
                .monospacedDigit()

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var encodedCornerPoints: String {
        cornerPoints
            .map { point in
                "\(Double(point.x).formatted(.number.precision(.fractionLength(0...4)))),\(Double(point.y).formatted(.number.precision(.fractionLength(0...4))))"
            }
            .joined(separator: ";")
    }

    private func scaledImageFrame(for image: UIImage, in container: CGSize) -> CGRect {
        guard image.size.width > 0,
              image.size.height > 0,
              container.width > 0,
              container.height > 0
        else {
            return CGRect(origin: .zero, size: container)
        }

        let imageRatio = image.size.width / image.size.height
        let containerRatio = container.width / container.height
        let size: CGSize

        if imageRatio > containerRatio {
            size = CGSize(width: container.width, height: container.width / imageRatio)
        } else {
            size = CGSize(width: container.height * imageRatio, height: container.height)
        }

        return CGRect(
            x: (container.width - size.width) / 2,
            y: (container.height - size.height) / 2,
            width: size.width,
            height: size.height
        )
    }

    private func normalizedPoint(_ point: CGPoint, in imageFrame: CGRect) -> CGPoint {
        guard imageFrame.width > 0, imageFrame.height > 0 else {
            return .zero
        }

        return CGPoint(
            x: min(max((point.x - imageFrame.minX) / imageFrame.width, 0), 1),
            y: min(max((point.y - imageFrame.minY) / imageFrame.height, 0), 1)
        )
    }

    private func denormalizedPoint(_ point: CGPoint, in imageFrame: CGRect) -> CGPoint {
        CGPoint(
            x: imageFrame.minX + point.x * imageFrame.width,
            y: imageFrame.minY + point.y * imageFrame.height
        )
    }

    private func decimalInputRow(_ title: String, text: Binding<String>, id: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 120)
                .accessibilityIdentifier(id)
        }
    }

    private func decimalValue(from text: String) -> Double? {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }

    private func formatted(_ value: Double) -> String {
        value.rounded() == value
            ? String(Int(value))
            : value.formatted(.number.precision(.fractionLength(0...1)))
    }
}

private struct GaugeMeasurementQuadOverlay: View {
    let points: [CGPoint]
    let imageFrame: CGRect

    var body: some View {
        Canvas { context, _ in
            guard points.count >= 2 else {
                return
            }

            var path = Path()
            path.move(to: denormalized(points[0]))

            for point in points.dropFirst() {
                path.addLine(to: denormalized(point))
            }

            if points.count == 4 {
                path.closeSubpath()
                context.fill(path, with: .color(AppTheme.Color.accent.opacity(0.16)))
            }

            context.stroke(path, with: .color(AppTheme.Color.accent), lineWidth: 2)
        }
        .allowsHitTesting(false)
    }

    private func denormalized(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: imageFrame.minX + point.x * imageFrame.width,
            y: imageFrame.minY + point.y * imageFrame.height
        )
    }
}

private struct GaugeMeasurementPointMarker: View {
    let index: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.Color.accent)
                .frame(width: 28, height: 28)

            Text("\(index)")
                .font(.caption.bold())
                .foregroundStyle(.white)
        }
        .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
    }
}

private struct GaugeCameraCaptureView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let parent: GaugeCameraCaptureView

        init(parent: GaugeCameraCaptureView) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct GaugePhoto4ptMeasurementView: View {
    @ObservedObject var viewModel: GaugeMeasureViewModel
    let targetID: UUID
    let swatchID: UUID
    let washState: GaugeWashState

    var body: some View {
        Photo4ptMeasurementView(
            viewModel: viewModel,
            targetID: targetID,
            swatchID: swatchID,
            washState: washState
        )
    }
}

struct MeasurementResultView: View {
    let methodTitle: String
    let washState: GaugeWashState
    let measuredWidth: Double
    let measuredHeight: Double
    let rawStitches: Double
    let rawRows: Double
    let confidence: String?
    let onSave: () async -> Bool

    @State private var isSaving = false

    var body: some View {
        Section("측정 결과") {
            resultRow("방식", value: methodTitle)
            resultRow("상태", value: washState.title)
            resultRow("감지 코 수", value: formatted(rawStitches))
            resultRow("감지 단 수", value: formatted(rawRows))

            if measuredWidth > 0 {
                resultRow("10cm 코 수", value: formatted(rawStitches / measuredWidth * 10))
            }

            if measuredHeight > 0 {
                resultRow("10cm 단 수", value: formatted(rawRows / measuredHeight * 10))
            }

            if let confidence {
                resultRow("신뢰도", value: confidence)
            }

            Button {
                Task {
                    isSaving = true
                    _ = await onSave()
                    isSaving = false
                }
            } label: {
                if isSaving {
                    ProgressView()
                } else {
                    Label("결과 저장", systemImage: "tray.and.arrow.down")
                }
            }
            .disabled(isSaving || measuredWidth <= 0 || measuredHeight <= 0)
            .accessibilityIdentifier(AppAccessibilityID.Tool.gaugePhotoResultSaveButton)
        }
    }

    private func resultRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
    }

    private func formatted(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }
}

struct MeasurementEditView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: GaugeMeasureViewModel
    let targetID: UUID
    let swatchID: UUID
    let measurement: GaugeMeasurement

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                AppFormSection(
                    title: "상태",
                    description: "수정할 측정값의 세탁 상태를 확인해요.",
                    systemImage: "drop.fill",
                    tint: AppTheme.Color.accent
                ) {
                Picker("세탁 상태", selection: $viewModel.measurementForm.washState) {
                    ForEach(GaugeWashState.allCases) { state in
                        Text(state.title).tag(state)
                    }
                }
                .pickerStyle(.segmented)
                    .padding(.vertical, 12)
                }

                AppFormSection(
                    title: "측정값",
                    description: "잘못 입력한 면적, 코 수, 단 수를 수정해요.",
                    systemImage: "ruler",
                    tint: AppTheme.Color.sage
                ) {
                    AppFormDecimalRow(title: "가로 길이(cm)", systemImage: "arrow.left.and.right", text: $viewModel.measurementForm.width)
                        .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeMeasurementWidthField)

                    AppFormDivider()

                    AppFormDecimalRow(title: "세로 길이(cm)", systemImage: "arrow.up.and.down", text: $viewModel.measurementForm.height)
                        .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeMeasurementHeightField)

                    AppFormDivider()

                    AppFormDecimalRow(title: "코 수", systemImage: "number", text: $viewModel.measurementForm.stitches)
                        .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeMeasurementStitchesField)

                    AppFormDivider()

                    AppFormDecimalRow(title: "단 수", systemImage: "number", text: $viewModel.measurementForm.rows)
                        .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeMeasurementRowsField)
                }

                if let normalized = viewModel.measurementForm.input.normalized {
                    AppFormSection(
                        title: "10cm 기준",
                        systemImage: "function",
                        tint: AppTheme.Color.amber
                    ) {
                        resultRow("코 수", value: "\(formatted(normalized.stitchesPer10cm))코")
                            .padding(.vertical, 10)

                        AppFormDivider()

                        resultRow("단 수", value: "\(formatted(normalized.rowsPer10cm))단")
                            .padding(.vertical, 10)
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    AppFormErrorBanner(message: errorMessage)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 96)
        }
        .safeAreaInset(edge: .bottom) {
            AppFormSubmitBar(
                isDisabled: viewModel.measurementForm.input.normalized == nil || viewModel.isSaving,
                accessibilityIdentifier: AppAccessibilityID.Tool.gaugeMeasurementSaveButton
            ) {
                Task {
                    let didSave = await viewModel.saveManualMeasurement(
                        targetID: targetID,
                        swatchID: swatchID,
                        washState: viewModel.measurementForm.washState,
                        input: viewModel.measurementForm.input,
                        existingMeasurementID: measurement.id
                    )
                    if didSave {
                        dismiss()
                    }
                }
            }
        }
        .warmScreenBackground()
        .navigationTitle("측정 수정")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("취소") {
                    dismiss()
                }
            }
        }
    }

    private func decimalInputRow(_ title: String, text: Binding<String>, id: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 120)
                .accessibilityIdentifier(id)
        }
    }

    private func resultRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
    }

    private func formatted(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }
}

struct MeasurementRowView: View {
    let measurement: GaugeMeasurement

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("\(measurement.washState.title) · \(measurement.method.title)", systemImage: icon)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text(measurement.updatedAt.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("\(formatted(measurement.finalStitches))코")
                Text("\(formatted(measurement.finalRows))단")
                Spacer()
                Text("\(formatted(measurement.measuredWidth))x\(formatted(measurement.measuredHeight))cm")
                    .foregroundStyle(.secondary)
            }
            .font(.footnote)

            if let autoConfidence = measurement.autoConfidence,
               !autoConfidence.isEmpty {
                Text("자동 측정 신뢰도: \(autoConfidence)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(AppTheme.Color.warmBackground, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppTheme.Color.warmDivider, lineWidth: 1)
        }
    }

    private var icon: String {
        switch measurement.method {
        case .manual:
            "ruler"
        case .photo4pt:
            "photo"
        case .marker:
            "scope"
        case .ar:
            "arkit"
        }
    }

    private func formatted(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }
}

struct QuickMeasureFlowView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: GaugeMeasureViewModel

    @State private var targetName = ""
    @State private var targetWidth = "10"
    @State private var targetHeight = "10"
    @State private var targetStitches = ""
    @State private var targetRows = ""
    @State private var needleSize = ""
    @State private var measuredWidth = "10"
    @State private var measuredHeight = "10"
    @State private var measuredStitches = ""
    @State private var measuredRows = ""
    @State private var washState: GaugeWashState = .before
    @State private var localMessage: String?
    @State private var isSaving = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                AppFormSection(
                    title: "목표 게이지",
                    description: "도안 기준 게이지를 빠르게 입력해요.",
                    systemImage: "target",
                    tint: AppTheme.Color.accent
                ) {
                    AppFormTextFieldRow(
                        title: "이름",
                        placeholder: "예: 도안 게이지",
                        systemImage: "textformat",
                        text: $targetName
                    )
                    .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeQuickTargetNameField)

                    AppFormDivider()
                    AppFormDecimalRow(title: "기준 가로(cm)", systemImage: "arrow.left.and.right", text: $targetWidth)
                    AppFormDivider()
                    AppFormDecimalRow(title: "기준 세로(cm)", systemImage: "arrow.up.and.down", text: $targetHeight)
                    AppFormDivider()
                    AppFormDecimalRow(title: "기준 코 수", systemImage: "number", text: $targetStitches)
                    AppFormDivider()
                    AppFormDecimalRow(title: "기준 단 수", systemImage: "number", text: $targetRows)
                }

                AppFormSection(
                    title: "스와치",
                    description: "이번 측정에 사용한 바늘과 세탁 상태를 남겨요.",
                    systemImage: "square.grid.3x3",
                    tint: AppTheme.Color.sage
                ) {
                    AppFormTextFieldRow(
                        title: "바늘",
                        placeholder: "예: 4.0mm",
                        systemImage: "ruler",
                        text: $needleSize
                    )
                    .accessibilityIdentifier(AppAccessibilityID.Tool.gaugeQuickNeedleField)

                    AppFormDivider()

                    Picker("세탁 상태", selection: $washState) {
                        ForEach(GaugeWashState.allCases) { state in
                            Text(state.title).tag(state)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 12)
                }

                AppFormSection(
                    title: "측정값",
                    description: "실제 잰 스와치 면적과 코/단 수를 입력해요.",
                    systemImage: "ruler",
                    tint: AppTheme.Color.rose
                ) {
                    AppFormDecimalRow(title: "가로 길이(cm)", systemImage: "arrow.left.and.right", text: $measuredWidth)
                    AppFormDivider()
                    AppFormDecimalRow(title: "세로 길이(cm)", systemImage: "arrow.up.and.down", text: $measuredHeight)
                    AppFormDivider()
                    AppFormDecimalRow(title: "코 수", systemImage: "number", text: $measuredStitches)
                    AppFormDivider()
                    AppFormDecimalRow(title: "단 수", systemImage: "number", text: $measuredRows)
                }

                if let normalized {
                    AppFormSection(
                        title: "10cm 기준",
                        systemImage: "function",
                        tint: AppTheme.Color.amber
                    ) {
                        resultRow("코 수", value: "\(formatted(normalized.stitchesPer10cm))코")
                            .padding(.vertical, 10)

                        AppFormDivider()

                        resultRow("단 수", value: "\(formatted(normalized.rowsPer10cm))단")
                            .padding(.vertical, 10)
                    }
                }

                if let message = localMessage ?? viewModel.errorMessage {
                    AppFormErrorBanner(message: message)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 96)
        }
        .safeAreaInset(edge: .bottom) {
            AppFormSubmitBar(
                isDisabled: normalized == nil || isSaving || viewModel.isSaving,
                accessibilityIdentifier: AppAccessibilityID.Tool.gaugeQuickSaveButton
            ) {
                Task {
                    await save()
                }
            }
        }
        .warmScreenBackground()
        .navigationTitle("빠른 측정")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("닫기") {
                    isPresented = false
                }
            }
        }
    }

    private var normalized: ManualMeasurementInput.Normalized? {
        ManualMeasurementInput(
            stitches: measuredStitches,
            rows: measuredRows,
            width: measuredWidth,
            height: measuredHeight
        )
        .normalized
    }

    private func save() async {
        let targetNameForLookup = targetName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !targetNameForLookup.isEmpty else {
            localMessage = "목표 이름을 입력해 주세요."
            return
        }

        isSaving = true
        defer { isSaving = false }

        let existingIDs = Set(viewModel.targets.map(\.id))
        viewModel.targetForm = GaugeTargetFormData(
            name: targetNameForLookup,
            width: targetWidth,
            height: targetHeight,
            stitches: targetStitches,
            rows: targetRows,
            recommendedNeedle: needleSize,
            gaugeAfterWash: washState == .after
        )

        guard await viewModel.saveTarget() else {
            return
        }

        guard let target = viewModel.targets.first(where: { !existingIDs.contains($0.id) })
            ?? viewModel.targets.first(where: { $0.name == targetNameForLookup }) else {
            localMessage = "저장된 목표 게이지를 찾지 못했어요."
            return
        }

        viewModel.swatchForm = GaugeSwatchFormData(needleSize: needleSize)

        guard await viewModel.saveSwatch(targetID: target.id),
              let refreshedTarget = viewModel.target(id: target.id),
              let swatch = refreshedTarget.swatches.first else {
            return
        }

        let didSaveMeasurement = await viewModel.saveManualMeasurement(
            targetID: refreshedTarget.id,
            swatchID: swatch.id,
            washState: washState,
            input: ManualMeasurementInput(
                stitches: measuredStitches,
                rows: measuredRows,
                width: measuredWidth,
                height: measuredHeight
            )
        )

        if didSaveMeasurement {
            isPresented = false
        }
    }

    private func decimalInputRow(_ title: String, text: Binding<String>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 120)
        }
    }

    private func resultRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
    }

    private func formatted(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }
}

struct GaugeQuickMeasureFlowView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: GaugeMeasureViewModel

    var body: some View {
        QuickMeasureFlowView(isPresented: $isPresented, viewModel: viewModel)
    }
}
