import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var history: HistoryStore
    @State private var showsClearConfirmation = false
    @State private var selectedRecord: TripRecord?

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                PageHeader(
                    title: "Vēsture",
                    subtitle: history.records.isEmpty
                        ? "Pabeigtie mērījumi parādīsies šeit."
                        : "\(history.records.count) saglabāti mērījumi šajā ierīcē."
                )

                if history.records.isEmpty {
                    EmptyStateCard(
                        icon: "clock.arrow.circlepath",
                        title: "Vēl nav mērījumu",
                        message: "Pabeidz demo braucienu vai reālu kontroles zonu, lai šeit saglabātu pirmo mērījumu."
                    )
                } else {
                    ForEach(history.records) { record in
                        TripRecordCard(
                            record: record,
                            onOpen: { selectedRecord = record },
                            onDelete: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    history.delete(record)
                                }
                            }
                        )
                    }

                    Button(role: .destructive) {
                        showsClearConfirmation = true
                    } label: {
                        Label("Dzēst visu vēsturi", systemImage: "trash")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .foregroundStyle(Theme.red)
                    .padding(.top, 2)
                }

                HStack(spacing: 5) {
                    Image(systemName: "lock.shield.fill")
                    Text("Visi mērījumi tiek glabāti tikai šajā ierīcē.")
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Theme.textTertiary)

                DisclaimerFooter()
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.top, 10)
            .padding(.bottom, 26)
        }
        .scrollIndicators(.hidden)
        .sheet(item: $selectedRecord) { record in
            HistoryDetailView(record: record)
        }
        .confirmationDialog(
            "Dzēst visu vēsturi?",
            isPresented: $showsClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Dzēst visu", role: .destructive) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    history.removeAll()
                }
            }
            Button("Atcelt", role: .cancel) {}
        } message: {
            Text("Šo darbību nevar atsaukt.")
        }
    }
}

private struct TripRecordCard: View {
    let record: TripRecord
    let onOpen: () -> Void
    let onDelete: () -> Void

    private var band: SpeedBand {
        SpeedBand(speedKmh: record.averageSpeedKmh, limitKmh: record.resolvedTargetSpeedKmh)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(record.road)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.7)
                    .foregroundStyle(record.isDemo ? Theme.amber : Theme.textPrimary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background {
                        Capsule()
                            .fill(record.isDemo ? Theme.amber.opacity(0.10) : Color.white.opacity(0.055))
                            .overlay {
                                Capsule().stroke(
                                    record.isDemo ? Theme.amber.opacity(0.25) : Theme.strokeStrong,
                                    lineWidth: 1
                                )
                            }
                    }

                if record.isDemo {
                    Text("DEMO")
                        .font(.system(size: 8, weight: .heavy))
                        .tracking(0.8)
                        .foregroundStyle(Theme.amber)
                }

                Spacer()

                Button(action: onOpen) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.mint)
                        .frame(width: 30, height: 30)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Atvērt mērījuma detaļas")

                Menu {
                    Button(role: .destructive, action: onDelete) {
                        Label("Dzēst", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                        .frame(width: 30, height: 30)
                        .contentShape(Rectangle())
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(record.zoneName)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(Fmt.dateTime(record.startedAt))
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Theme.textSecondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(Fmt.speed(record.averageSpeedKmh))
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(band.tint)

                Text("km/h")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)

                Spacer()

                if record.resolvedTargetSpeedKmh != record.speedLimitKmh {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("MĒRĶIS")
                            .font(.system(size: 8, weight: .bold))
                            .tracking(1.1)
                            .foregroundStyle(Theme.amber)

                        Text("\(record.resolvedTargetSpeedKmh)")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(Theme.amber)
                    }

                    Spacer(minLength: 8)
                }

                VStack(alignment: .trailing, spacing: 2) {
                    Text("OFICIĀLAIS")
                        .font(.system(size: 8, weight: .bold))
                        .tracking(1.1)
                        .foregroundStyle(Theme.textTertiary)

                    Text("\(record.speedLimitKmh)")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            Rectangle()
                .fill(Theme.stroke)
                .frame(height: 1)

            HStack(spacing: 14) {
                Label(Fmt.distance(record.distanceMeters), systemImage: "road.lanes")
                Label(Fmt.duration(record.duration), systemImage: "clock")
                Spacer()
                Text(band.label)
                    .foregroundStyle(band.tint)
            }
            .font(.system(size: 10.5, weight: .medium))
            .foregroundStyle(Theme.textTertiary)
        }
        .dashboardCard()
    }
}
