//
//  ProjectCardView.swift
//  KnitGether
//
//  Created by yu haeun on 6/2/26.
//

import SwiftUI

struct ProjectCardView: View {
    let project: KnittingProject

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                    .accessibilityLabel(project.isFavorite ? "Favorite project" : "Not favorite")
            }

            if let patternName = project.patternName {
                Label(patternName, systemImage: "doc.text")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(project.memo)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(2)

            Divider()

            HStack(spacing: 16) {
                ProjectDateLabel(title: "Started", date: project.startDate)
                ProjectDateLabel(title: "Last worked", date: project.lastWorkedDate)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct ProjectDateLabel: View {
    let title: String
    let date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(date.formatted(.dateTime.month(.abbreviated).day().year()))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ProjectCardView(project: SampleKnittingData.projects[0])
        .padding()
}
