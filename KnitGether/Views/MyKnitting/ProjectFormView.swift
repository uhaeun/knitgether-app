//
//  ProjectFormView.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import SwiftUI

struct ProjectFormView: View {
    @Binding var formData: ProjectFormData
    let includesPatternName: Bool
    let includesToolSelection: Bool
    let availablePatterns: [PatternDocument]
    let availableYarns: [Yarn]
    let availableNeedles: [Needle]
    let availableTools: [ToolItem]
    let onRegisterYarn: (() -> Void)?
    let onRegisterNeedle: (() -> Void)?
    let onRegisterTool: (() -> Void)?

    init(
        formData: Binding<ProjectFormData>,
        includesPatternName: Bool,
        includesToolSelection: Bool = false,
        availablePatterns: [PatternDocument] = [],
        availableYarns: [Yarn] = [],
        availableNeedles: [Needle] = [],
        availableTools: [ToolItem] = [],
        onRegisterYarn: (() -> Void)? = nil,
        onRegisterNeedle: (() -> Void)? = nil,
        onRegisterTool: (() -> Void)? = nil
    ) {
        _formData = formData
        self.includesPatternName = includesPatternName
        self.includesToolSelection = includesToolSelection
        self.availablePatterns = availablePatterns
        self.availableYarns = availableYarns
        self.availableNeedles = availableNeedles
        self.availableTools = availableTools
        self.onRegisterYarn = onRegisterYarn
        self.onRegisterNeedle = onRegisterNeedle
        self.onRegisterTool = onRegisterTool
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            projectSection
            scheduleSection
            memoSection

            materialsSection

            if includesToolSelection {
                toolsSection
            }

            if includesPatternName {
                patternSection
            }
        }
    }

    private var projectSection: some View {
        ProjectFormSection(
            title: "프로젝트",
            description: "작업 이름과 현재 상태를 정리해요.",
            systemImage: "heart.text.square.fill",
            tint: AppTheme.Color.accent
        ) {
            VStack(spacing: 0) {
                ProjectTextInput(
                    title: "프로젝트 이름",
                    placeholder: "예: 여름 가디건",
                    systemImage: "text.cursor",
                    text: $formData.name,
                    identifier: AppAccessibilityID.Project.nameField
                )

                ProjectDivider()

                Picker(selection: $formData.status) {
                    ForEach(ProjectStatus.allCases) { status in
                        Text(status.detailTitle).tag(status)
                    }
                } label: {
                    ProjectPickerLabel(
                        title: "상태",
                        value: formData.status.detailTitle,
                        systemImage: "flag",
                        tint: AppTheme.statusColorSoft(for: formData.status).fg
                    )
                }
                .pickerStyle(.menu)
                .tint(AppTheme.Color.accent)
                .accessibilityIdentifier(AppAccessibilityID.Project.statusPicker)

                ProjectDivider()

                ProjectDatePickerRow(
                    title: "시작일",
                    systemImage: "calendar",
                    selection: $formData.startDate
                )

                ProjectDivider()

                ProjectToggleRow(
                    title: "즐겨찾기",
                    subtitle: "자주 보는 프로젝트를 목록 상단에서 찾기 쉽게 표시해요.",
                    systemImage: formData.isFavorite ? "star.fill" : "star",
                    tint: AppTheme.Color.amber,
                    isOn: $formData.isFavorite
                )
            }
        }
    }

    private var scheduleSection: some View {
        ProjectFormSection(
            title: "일정",
            description: "목표일과 완료일은 선택 사항이에요.",
            systemImage: "calendar.badge.clock",
            tint: AppTheme.Color.sage
        ) {
            VStack(spacing: 0) {
                ProjectToggleRow(
                    title: "목표일 설정",
                    subtitle: "마감이나 계획이 있을 때 켜 주세요.",
                    systemImage: "target",
                    tint: AppTheme.Color.sage,
                    isOn: $formData.hasTargetDate
                )

                if formData.hasTargetDate {
                    ProjectDivider()

                    ProjectDatePickerRow(
                        title: "목표일",
                        systemImage: "calendar.circle",
                        selection: $formData.targetDate
                    )
                }

                ProjectDivider()

                ProjectToggleRow(
                    title: "완료일 설정",
                    subtitle: "완성한 프로젝트라면 완료일을 남겨요.",
                    systemImage: "checkmark.seal",
                    tint: AppTheme.Color.lavender,
                    isOn: $formData.hasFinishedAt
                )

                if formData.hasFinishedAt {
                    ProjectDivider()

                    ProjectDatePickerRow(
                        title: "완료일",
                        systemImage: "calendar.badge.checkmark",
                        selection: $formData.finishedAt
                    )
                }
            }
        }
    }

    private var memoSection: some View {
        ProjectFormSection(
            title: "작업 메모",
            description: "실수하기 쉬운 부분, 수정할 점, 참고 사항을 적어두세요.",
            systemImage: "note.text",
            tint: AppTheme.Color.slate
        ) {
            TextEditor(text: $formData.memo)
                .frame(minHeight: 128)
                .padding(10)
                .scrollContentBackground(.hidden)
                .background(AppTheme.Color.warmBackground, in: RoundedRectangle(cornerRadius: AppTheme.Radius.small))
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                        .stroke(AppTheme.Color.warmDivider, lineWidth: 1)
                }
                .accessibilityIdentifier(AppAccessibilityID.Project.memoField)
        }
    }

    private var materialsSection: some View {
        ProjectFormSection(
            title: "재료",
            description: "창고에 등록한 실과 바늘을 프로젝트에 연결해요.",
            systemImage: "shippingbox.fill",
            tint: AppTheme.Color.amber
        ) {
            VStack(spacing: 0) {
                if availableYarns.isEmpty && formData.yarnSummaryText == nil {
                    ProjectInfoLabel(
                        text: "창고에 등록된 실이 없어요.",
                        systemImage: "circle.hexagongrid",
                        tint: AppTheme.Color.amber
                    )
                } else {
                    Picker(selection: yarnSelection) {
                        Text("선택 안 함").tag(UUID?.none)

                        ForEach(availableYarns) { yarn in
                            Text(yarnPickerTitle(for: yarn)).tag(Optional(yarn.id))
                        }
                    } label: {
                        ProjectPickerLabel(
                            title: "실",
                            value: formData.yarnSummaryText ?? "선택 안 함",
                            systemImage: "circle.hexagongrid",
                            tint: AppTheme.Color.amber
                        )
                    }
                    .pickerStyle(.menu)
                    .tint(AppTheme.Color.accent)
                    .accessibilityIdentifier(AppAccessibilityID.Project.yarnPicker)
                }

                if let onRegisterYarn {
                    registerButtonRow(
                        title: "새 실 등록해서 연결",
                        tint: AppTheme.Color.amber,
                        action: onRegisterYarn
                    )
                }

                ProjectDivider()

                if availableNeedles.isEmpty && formData.needleSummaryText == nil {
                    ProjectInfoLabel(
                        text: "창고에 등록된 바늘이 없어요.",
                        systemImage: "ruler",
                        tint: AppTheme.Color.sage
                    )
                } else {
                    Picker(selection: needleSelection) {
                        Text("선택 안 함").tag(UUID?.none)

                        ForEach(availableNeedles) { needle in
                            Text(needlePickerTitle(for: needle)).tag(Optional(needle.id))
                        }
                    } label: {
                        ProjectPickerLabel(
                            title: "바늘",
                            value: formData.needleSummaryText ?? "선택 안 함",
                            systemImage: "ruler",
                            tint: AppTheme.Color.sage
                        )
                    }
                    .pickerStyle(.menu)
                    .tint(AppTheme.Color.accent)
                    .accessibilityIdentifier(AppAccessibilityID.Project.needlePicker)
                }

                if let onRegisterNeedle {
                    registerButtonRow(
                        title: "새 바늘 등록해서 연결",
                        tint: AppTheme.Color.sage,
                        action: onRegisterNeedle
                    )
                }
            }
        }
    }

    private func registerButtonRow(
        title: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(tint)
                    .frame(width: 24)

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)

                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .padding(.top, 8)
            .padding(.bottom, 2)
        }
        .buttonStyle(.plain)
    }

    private var toolsSection: some View {
        ProjectFormSection(
            title: "도구",
            description: "함께 쓸 도구를 골라 두면 작업 화면에서 바로 확인할 수 있어요.",
            systemImage: "wrench.and.screwdriver.fill",
            tint: AppTheme.Color.slate
        ) {
            VStack(spacing: 0) {
                if availableTools.isEmpty {
                    ProjectInfoLabel(
                        text: "창고에 등록된 도구가 없어요.",
                        systemImage: "wrench.and.screwdriver",
                        tint: AppTheme.Color.slate
                    )
                } else {
                    ForEach(Array(availableTools.enumerated()), id: \.element.id) { index, tool in
                        if index > 0 {
                            ProjectDivider()
                        }

                        Button {
                            formData.toggleTool(tool)
                        } label: {
                            HStack(spacing: 12) {
                                ProjectFieldIcon(
                                    systemImage: formData.isToolSelected(tool) ? "checkmark.circle.fill" : "circle",
                                    tint: formData.isToolSelected(tool) ? AppTheme.Color.accent : AppTheme.Color.slate
                                )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tool.name)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(.primary)

                                    Text(tool.type)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer(minLength: 0)
                            }
                            .contentShape(Rectangle())
                            .padding(.vertical, 2)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let onRegisterTool {
                    registerButtonRow(
                        title: "새 도구 등록해서 연결",
                        tint: AppTheme.Color.slate,
                        action: onRegisterTool
                    )
                }
            }
        }
    }

    private var patternSection: some View {
        ProjectFormSection(
            title: "도안",
            description: "도안 창고에서 가져오거나 수동 이름으로 연결할 수 있어요.",
            systemImage: "doc.text.fill",
            tint: AppTheme.Color.lavender
        ) {
            VStack(alignment: .leading, spacing: 0) {
                if !availablePatterns.isEmpty {
                    Picker(selection: patternSelection) {
                        Text("선택 안 함").tag(UUID?.none)

                        ForEach(availablePatterns) { pattern in
                            Text(patternPickerTitle(for: pattern)).tag(Optional(pattern.id))
                        }
                    } label: {
                        ProjectPickerLabel(
                            title: "도안 창고",
                            value: formData.patternSummaryText ?? "선택 안 함",
                            systemImage: "books.vertical",
                            tint: AppTheme.Color.lavender
                        )
                    }
                    .pickerStyle(.menu)
                    .tint(AppTheme.Color.accent)
                    .accessibilityIdentifier(AppAccessibilityID.Project.patternPicker)

                    ProjectDivider()
                }

                ProjectTextInput(
                    title: "수동 도안 이름",
                    placeholder: "예: Basic Cardigan Pattern",
                    systemImage: "square.and.pencil",
                    text: manualPatternName
                )

                ProjectDivider()

                patternStateLabel
            }
        }
    }

    private var patternStateLabel: some View {
        Group {
            if formData.trimmedPatternName.isEmpty {
                ProjectInfoLabel(
                    text: "도안 없음",
                    systemImage: "doc.badge.plus",
                    tint: AppTheme.Color.slate
                )
            } else if formData.patternDocumentId != nil {
                ProjectInfoLabel(
                    text: "도안 창고에서 가져온 사본이 저장돼요.",
                    systemImage: "doc.text.fill",
                    tint: AppTheme.Color.lavender
                )
            } else {
                ProjectInfoLabel(
                    text: "수동 도안 이름으로 사본이 저장돼요.",
                    systemImage: "square.and.pencil",
                    tint: AppTheme.Color.accent
                )
            }
        }
    }

    private var yarnSelection: Binding<UUID?> {
        Binding(
            get: { formData.yarnId },
            set: { selectedID in
                formData.selectYarn(availableYarns.first { $0.id == selectedID })
            }
        )
    }

    private var needleSelection: Binding<UUID?> {
        Binding(
            get: { formData.needleId },
            set: { selectedID in
                formData.selectNeedle(availableNeedles.first { $0.id == selectedID })
            }
        )
    }

    private var patternSelection: Binding<UUID?> {
        Binding(
            get: { formData.patternDocumentId },
            set: { selectedID in
                formData.selectPattern(availablePatterns.first { $0.id == selectedID })
            }
        )
    }

    private var manualPatternName: Binding<String> {
        Binding(
            get: { formData.patternName },
            set: { name in
                formData.setManualPatternName(name)
            }
        )
    }

    private func yarnPickerTitle(for yarn: Yarn) -> String {
        [
            yarn.name,
            yarn.brand,
            yarn.colorway,
            yarn.weight
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }
        .joined(separator: " · ")
    }

    private func needlePickerTitle(for needle: Needle) -> String {
        [
            needle.name,
            needle.needleType,
            needle.size,
            needle.length
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }
        .joined(separator: " · ")
    }

    private func patternPickerTitle(for pattern: PatternDocument) -> String {
        [
            pattern.title,
            pattern.designer,
            pattern.fileName
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }
        .joined(separator: " · ")
    }
}

#Preview {
    ProjectFormPreview()
}

private struct ProjectFormPreview: View {
    @State private var formData = ProjectFormData()

    var body: some View {
        ScrollView {
            ProjectFormView(formData: $formData, includesPatternName: true)
                .padding()
        }
        .warmScreenBackground()
    }
}

private struct ProjectFormSection<Content: View>: View {
    let title: String
    let description: String
    let systemImage: String
    let tint: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(tint)
                    .frame(width: 38, height: 38)
                    .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: AppTheme.Radius.small))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3.weight(.semibold))

                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            content()
                .padding(AppTheme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .appCard()
        }
    }
}

private struct ProjectTextInput: View {
    let title: String
    let placeholder: String
    let systemImage: String
    @Binding var text: String
    var identifier: String? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ProjectFieldIcon(systemImage: systemImage, tint: AppTheme.Color.accent)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                textField
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var textField: some View {
        let base = TextField(placeholder, text: $text)
            .font(.body.weight(.semibold))
            .textInputAutocapitalization(.sentences)
            .submitLabel(.done)

        if let identifier {
            base.accessibilityIdentifier(identifier)
        } else {
            base
        }
    }
}

private struct ProjectPickerLabel: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            ProjectFieldIcon(systemImage: systemImage, tint: tint)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 12)

            Image(systemName: "chevron.up.chevron.down")
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 2)
    }
}

private struct ProjectDatePickerRow: View {
    let title: String
    let systemImage: String
    @Binding var selection: Date

    var body: some View {
        DatePicker(
            selection: $selection,
            displayedComponents: .date
        ) {
            HStack(spacing: 12) {
                ProjectFieldIcon(systemImage: systemImage, tint: AppTheme.Color.sage)

                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
            }
        }
        .datePickerStyle(.compact)
        .tint(AppTheme.Color.accent)
        .padding(.vertical, 2)
    }
}

private struct ProjectToggleRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(alignment: .top, spacing: 12) {
                ProjectFieldIcon(systemImage: systemImage, tint: tint)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body.weight(.semibold))

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .tint(tint)
        .padding(.vertical, 2)
    }
}

private struct ProjectInfoLabel: View {
    let text: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .frame(width: 24)

            Text(text)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }
}

private struct ProjectFieldIcon: View {
    let systemImage: String
    let tint: Color

    var body: some View {
        Image(systemName: systemImage)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(tint)
            .frame(width: 30, height: 30)
            .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: AppTheme.Radius.small))
    }
}

private struct ProjectDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 42)
            .padding(.vertical, 12)
    }
}
