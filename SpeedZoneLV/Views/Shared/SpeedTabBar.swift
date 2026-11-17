import SwiftUI

struct SpeedTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 3) {
            tabButton(.ride)
            tabButton(.history)
            tabButton(.settings)
        }
        .padding(6)
        .background {
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    Capsule(style: .continuous)
                        .fill(Theme.surface.opacity(0.76))
                }
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(Theme.strokeStrong, lineWidth: 1)
                }
                .shadow(color: Color.black.opacity(0.55), radius: 26, x: 0, y: 14)
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.82), value: selection)
    }

    private func tabButton(_ tab: AppTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                selection = tab
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: tab.icon)
                    .font(.system(size: 14, weight: .semibold))

                if selection == tab {
                    Text(tab.title)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                        .transition(.opacity.combined(with: .scale(scale: 0.94)))
                }
            }
            .foregroundStyle(selection == tab ? Theme.mint : Theme.textTertiary)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .contentShape(Capsule())
            .background {
                if selection == tab {
                    Capsule(style: .continuous)
                        .fill(Theme.mint.opacity(0.11))
                        .overlay {
                            Capsule(style: .continuous)
                                .stroke(Theme.mint.opacity(0.18), lineWidth: 1)
                        }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(selection == tab ? .isSelected : [])
    }
}
