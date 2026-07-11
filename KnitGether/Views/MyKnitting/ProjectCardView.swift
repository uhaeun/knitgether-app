//
//  ProjectCardView.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import SwiftUI

struct ProjectCardView: View {
    let project: KnittingProject

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            thumbnail

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline, spacing: 7) {
                    Text(project.name)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.Color.primaryText)
                        .lineLimit(1)

                    StatusBadgeView(status: project.status)

                    if project.syncStatus != .synced {
                        syncDot
                    }

                    Spacer(minLength: 0)
                }

                if let rowProgress {
                    ProgressView(value: rowProgress)
                        .tint(AppTheme.Color.softAccent)
                        .progressViewStyle(.linear)
                        .frame(height: 4)
                        .clipShape(Capsule())
                }

                Text(rowMetaText)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    compactChip(
                        title: patternText,
                        systemImage: project.hasPatternAttached ? "doc.text.fill" : "doc.badge.plus"
                    )

                    compactChip(
                        title: materialText,
                        systemImage: project.hasMaterialsAttached ? "shippingbox.fill" : "shippingbox"
                    )
                }
                .lineLimit(1)

                if project.targetDate != nil || project.finishedAt != nil {
                    Text(scheduleStatusText)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(scheduleColor)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: project.isFavorite ? "star.fill" : "star")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(project.isFavorite ? Color(red: 0.788, green: 0.647, blue: 0.353) : .secondary.opacity(0.55))
                .accessibilityLabel(project.isFavorite ? "즐겨찾기" : "즐겨찾기 아님")
        }
        .padding(14)
        .appCard(cornerRadius: 20)
    }

    private var thumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.Color.accentSoft,
                            AppTheme.Color.knitTexture
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 5) {
                ForEach(0..<5, id: \.self) { _ in
                    Capsule()
                        .fill(Color.white.opacity(0.42))
                        .frame(width: 74, height: 2)
                        .rotationEffect(.degrees(-24))
                }
            }
            .offset(x: -1)

            Image(systemName: project.hasPatternAttached ? "doc.text" : "plus")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppTheme.Color.accent.opacity(0.8))
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppTheme.Color.warmDivider, lineWidth: 1)
        }
        .accessibilityLabel("프로젝트 썸네일 자리")
    }

    private var syncDot: some View {
        Image(systemName: project.syncStatus.badgeSystemImage)
            .font(.caption2.weight(.bold))
            .foregroundStyle(AppTheme.Color.accent)
            .padding(5)
            .background(AppTheme.Color.accentSoft, in: Circle())
            .accessibilityLabel("서버 저장 상태: \(project.syncStatus.displayTitle)")
    }

    private func compactChip(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(AppTheme.Color.accent)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(AppTheme.Color.accentSoft, in: Capsule())
    }

    private var rowProgress: Double? {
        guard let targetRow = project.rowCounter.targetRow, targetRow > 0 else {
            return nil
        }

        return min(max(Double(project.rowCounter.currentRow) / Double(targetRow), 0), 1)
    }

    private var rowMetaText: String {
        let rowText: String

        if let targetRow = project.rowCounter.targetRow, targetRow > 0 {
            rowText = "\(project.rowCounter.currentRow)/\(targetRow)단"
        } else {
            rowText = "현재 \(project.rowCounter.currentRow)단"
        }

        return "\(rowText) · 최근 작업 \(formattedDate(project.lastWorkedAt))"
    }

    private var patternText: String {
        guard let title = project.patternCopy?.titleSnapshot, !title.isEmpty else {
            return "도안 없음"
        }

        return title
    }

    private var materialText: String {
        if let yarnSummary = project.yarnSummaryText {
            return yarnSummary
        }

        if let needleSummary = project.needleSummaryText {
            return needleSummary
        }

        return "재료 미연결"
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else {
            return "없음"
        }

        return date.formatted(.dateTime.month().day())
    }

    private var scheduleStatusText: String {
        if let finishedAt = project.finishedAt {
            return "완료일 \(formattedDate(finishedAt))"
        }

        guard let days = project.daysUntilTarget() else {
            return "목표일 없음"
        }

        if days > 0 {
            return "목표일까지 D-\(days)"
        }

        if days == 0 {
            return "목표일 D-Day"
        }

        return "목표일 D+\(-days)"
    }

    private var scheduleColor: Color {
        if project.finishedAt != nil {
            return .green
        }

        guard let days = project.daysUntilTarget() else {
            return .secondary
        }

        return days < 0 ? .red : .secondary
    }

}

#Preview {
    ProjectCardView(project: SampleData.projects[0])
        .padding()
}
