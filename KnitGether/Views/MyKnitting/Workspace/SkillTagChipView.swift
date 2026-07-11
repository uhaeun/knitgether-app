import SwiftUI

struct SkillTagChipView: View {
    let tag: ResolvedSkillTag
    var tapAction: ((ResolvedSkillTag) -> Void)?

    var body: some View {
        if let tapAction, tag.isRegistered {
            Button {
                tapAction(tag)
            } label: {
                chipContent
            }
            .buttonStyle(.plain)
            .accessibilityHint("스킬 설명과 뜨개니메이션을 열어요.")
        } else {
            chipContent
        }
    }

    private var chipContent: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(levelColor)
                .frame(width: 8, height: 8)

            Text(tag.displayTag)
                .font(.caption.bold())

            Text(normalizedLevel)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(levelColor.opacity(0.14), in: Capsule())
        .overlay {
            Capsule()
                .stroke(levelColor.opacity(0.5))
        }
        .accessibilityLabel("\(tag.displayTag), \(tag.displayTag) 스킬 이해도 \(normalizedLevel)")
    }

    private var normalizedLevel: String {
        SkillLevelFormatter.normalizedLevel(tag.level)
    }

    private var levelColor: Color {
        SkillLevelFormatter.color(for: normalizedLevel)
    }
}

struct WorkspaceFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if maxWidth > 0, currentX > 0, currentX + size.width > maxWidth {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }

            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return CGSize(width: maxWidth, height: currentY + rowHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX > bounds.minX, currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += rowHeight + spacing
                rowHeight = 0
            }

            subview.place(
                at: CGPoint(x: currentX, y: currentY),
                proposal: ProposedViewSize(size)
            )
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
