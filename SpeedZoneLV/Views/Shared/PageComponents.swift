import SwiftUI

struct PageHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)

            Text(subtitle)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 10)
        .padding(.bottom, 4)
    }
}

struct DisclaimerFooter: View {
    var text: String = "GPS aprēķins ir informatīvs un nav oficiāls ātruma mērījums. Ceļa zīmes un spēkā esošie noteikumi ir noteicošie."

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.textTertiary)
                .padding(.top, 1)

            Text(text)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Theme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    var tint: Color = Theme.textSecondary
    var valueTint: Color = Theme.textPrimary

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Theme.textSecondary)

            Spacer(minLength: 12)

            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(valueTint)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct EmptyStateCard: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Theme.ice.opacity(0.10))
                    .frame(width: 64, height: 64)

                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(Theme.ice)
            }

            VStack(spacing: 5) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)

                Text(message)
                    .font(.system(size: 12.5, weight: .regular))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .dashboardCard()
    }
}
