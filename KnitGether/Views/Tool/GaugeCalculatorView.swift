//
//  GaugeCalculatorView.swift
//  KnitGether
//
//  Created by yu haeun on 6/7/26.
//

import SwiftUI

struct GaugeCalculatorView: View {
    @StateObject private var viewModel = GaugeCalculatorViewModel()

    var body: some View {
        Form {
            Section("게이지 샘플") {
                decimalInputRow("가로 길이(cm)", text: $viewModel.sampleWidthCm)
                decimalInputRow("세로 길이(cm)", text: $viewModel.sampleHeightCm)
                decimalInputRow("코 수", text: $viewModel.stitchCount)
                decimalInputRow("단 수", text: $viewModel.rowCount)
            }

            Section("목표 크기") {
                decimalInputRow("목표 가로(cm)", text: $viewModel.targetWidthCm)
                decimalInputRow("목표 세로(cm)", text: $viewModel.targetHeightCm)
            }

            Section("기록") {
                TextField("사용 바늘", text: $viewModel.needle)

                TextEditor(text: $viewModel.memo)
                    .frame(minHeight: 88)
                    .overlay(alignment: .topLeading) {
                        if viewModel.memo.isEmpty {
                            Text("메모")
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                        }
                    }
            }

            Section("계산 결과") {
                resultContent
            }
        }
        .navigationTitle("게이지 계산기")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("초기화") {
                    viewModel.reset()
                }
                .disabled(!viewModel.hasAnyInput)
            }
        }
    }

    @ViewBuilder
    private var resultContent: some View {
        if let result = viewModel.result {
            VStack(alignment: .leading, spacing: 18) {
                resultGroup(title: "10cm 기준 게이지") {
                    resultRow("10cm 기준 코 수", value: "\(formattedDecimal(result.stitchesPer10Cm))코")
                    resultRow("10cm 기준 단 수", value: "\(formattedDecimal(result.rowsPer10Cm))단")
                }

                Divider()

                resultGroup(title: "예상 필요 코/단 수") {
                    resultRow("목표 가로에 필요한 코 수", value: "약 \(result.targetStitches)코")
                    resultRow("목표 세로에 필요한 단 수", value: "약 \(result.targetRows)단")
                }
            }
            .padding(.vertical, 6)
        } else {
            Label(viewModel.guidanceMessage, systemImage: "info.circle")
                .foregroundStyle(.secondary)
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

    private func resultGroup<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)

            content()
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

    private func formattedDecimal(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }
}

#Preview {
    NavigationStack {
        GaugeCalculatorView()
    }
}
