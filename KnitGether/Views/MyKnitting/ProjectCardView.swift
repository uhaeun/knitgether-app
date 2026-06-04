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
        HStack(alignment: .top, spacing: 14) {
            thumbnail

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(project.name)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        StatusBadgeView(status: project.status)
                    }

                    Spacer()

                    Image(systemName: project.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(project.isFavorite ? .yellow : .secondary)
                        .accessibilityLabel(project.isFavorite ? "즐겨찾기" : "즐겨찾기 아님")
                }

                Label(
                    project.hasPatternAttached ? "도안 있음" : "도안 없음",
                    systemImage: project.hasPatternAttached ? "doc.text.fill" : "doc.badge.plus"
                )
                .font(.subheadline)
                .foregroundStyle(project.hasPatternAttached ? .green : .secondary)

                HStack(spacing: 14) {
                    metadata(title: "시작일", value: formattedDate(project.startDate))
                    metadata(title: "최근 작업", value: formattedDate(project.lastWorkedAt))
                    metadata(title: "총 작업 시간", value: formattedDuration(project.totalWorkTime))
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var thumbnail: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(.tertiarySystemBackground))
            .frame(width: 64, height: 64)
            .overlay {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("프로젝트 썸네일 자리")
    }

    private func metadata(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else {
            return "없음"
        }

        return date.formatted(.dateTime.month(.abbreviated).day().year())
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = max(0, Int(duration.rounded()))
        let totalMinutes = totalSeconds / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return "\(hours)시간 \(minutes)분"
        }

        if minutes > 0 {
            return "\(minutes)분 \(seconds)초"
        }

        return "\(seconds)초"
    }
}

#Preview {
    ProjectCardView(project: SampleData.projects[0])
        .padding()
}
