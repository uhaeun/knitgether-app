//
//  StatusBadgeView.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import SwiftUI

struct StatusBadgeView: View {
    let status: ProjectStatus

    var body: some View {
        let colors = AppTheme.statusColorSoft(for: status)

        Text(status.badgeTitle)
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(colors.fg)
            .background(colors.bg, in: Capsule())
    }
}

#Preview {
    HStack {
        ForEach(ProjectStatus.allCases) { status in
            StatusBadgeView(status: status)
        }
    }
    .padding()
}
