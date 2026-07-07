import SwiftUI

/// Sheet that lets the user configure Distill's two daily notifications.
///
/// Present this view as a sheet — it manages its own `NavigationStack`
/// so the title and drag indicator render correctly at any detent.
///
/// ```swift
/// .sheet(isPresented: $showNotifications) {
///     NotificationSettingsView(service: notificationService)
///         .presentationDetents([.medium, .large])
///         .presentationDragIndicator(.visible)
/// }
/// ```
struct NotificationSettingsView: View {

    let service: NotificationService

    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            Form {

                // ── Permission denied banner ──────────────────────────────
                if service.authorizationStatus == .denied {
                    Section { permissionDeniedRow }
                }

                // ── End-of-day reminder ───────────────────────────────────
                Section {
                    Toggle(isOn: reminderEnabledBinding) {
                        Label("End-of-day reminder", systemImage: "moon.stars")
                    }

                    if service.reminderEnabled {
                        DatePicker(
                            "Remind me at",
                            selection: reminderTimeBinding,
                            displayedComponents: .hourAndMinute
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                } header: {
                    Text("Daily reminder")
                } footer: {
                    Text(
                        "A time-sensitive alert that arrives even when your phone " +
                        "is on Focus. Your safety net so no day goes unpainted."
                    )
                }

                // ── Gentle nudge ──────────────────────────────────────────
                Section {
                    Toggle(isOn: nudgeEnabledBinding) {
                        Label("Painting nudge", systemImage: "paintbrush")
                    }

                    if service.nudgeEnabled {
                        DatePicker(
                            "Nudge me at",
                            selection: nudgeTimeBinding,
                            displayedComponents: .hourAndMinute
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                } header: {
                    Text("Gentle prompt")
                } footer: {
                    Text(
                        "A quiet nudge to look for something worth painting. " +
                        "No urgency — just a reminder to keep your eyes open."
                    )
                }
            }
            .animation(.default, value: service.reminderEnabled)
            .animation(.default, value: service.nudgeEnabled)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .task { await service.refreshAuthorizationStatus() }
        }
    }

    // MARK: - Permission Denied Banner

    private var permissionDeniedRow: some View {
        HStack(spacing: 14) {
            Image(systemName: "bell.slash.fill")
                .font(.title2)
                .foregroundStyle(.orange)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text("Notifications are off")
                    .font(.subheadline.weight(.semibold))
                Text("Allow notifications for Distill in Settings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Settings") {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                openURL(url)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Notifications are off. Open Settings to allow notifications for Distill.")
        .accessibilityAction(named: "Open Settings") {
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            openURL(url)
        }
    }

    // MARK: - Bindings
    //
    // The async setter methods on `NotificationService` can't be driven by a
    // plain `$service.reminderEnabled` binding, so we wrap them explicitly.

    private var reminderEnabledBinding: Binding<Bool> {
        Binding(
            get: { service.reminderEnabled },
            set: { newValue in Task { await service.setReminderEnabled(newValue) } }
        )
    }

    private var reminderTimeBinding: Binding<Date> {
        Binding(
            get: { service.reminderTime },
            set: { service.setReminderTime($0) }
        )
    }

    private var nudgeEnabledBinding: Binding<Bool> {
        Binding(
            get: { service.nudgeEnabled },
            set: { newValue in Task { await service.setNudgeEnabled(newValue) } }
        )
    }

    private var nudgeTimeBinding: Binding<Date> {
        Binding(
            get: { service.nudgeTime },
            set: { service.setNudgeTime($0) }
        )
    }
}

// MARK: - Preview

#Preview("Both off") {
    NotificationSettingsView(service: NotificationService())
        .presentationDetents([.medium, .large])
}
