import SwiftUI
import DoseCore

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("themePreference") private var theme = ThemePreference.system
    @AppStorage("timeSensitive") private var timeSensitive = true
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage(DoseLeftStorage.iCloudSyncDefaultsKey, store: DoseLeftStorage.sharedDefaults)
    private var iCloudSyncEnabled = false
    @State private var pendingSyncChange = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    section("Notifications") {
                        row {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Time-sensitive").font(DL.Text.body17).foregroundStyle(DL.text)
                                Text("Break through Focus and silent modes.")
                                    .font(DL.Text.footnote13).foregroundStyle(DL.text2)
                            }
                            Spacer()
                            Toggle("", isOn: $timeSensitive).labelsHidden().tint(DLAccent.sage.color)
                        }
                        Divider().padding(.leading, 16)
                        row {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sound").font(DL.Text.body17).foregroundStyle(DL.text)
                                Text("Play a sound when a reminder fires.")
                                    .font(DL.Text.footnote13).foregroundStyle(DL.text2)
                            }
                            Spacer()
                            Toggle("", isOn: $soundEnabled).labelsHidden().tint(DLAccent.sage.color)
                        }
                    }
                    section("Appearance") {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Text("Theme").font(DL.Text.body17).foregroundStyle(DL.text)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 12)

                            Picker("", selection: $theme) {
                                ForEach(ThemePreference.allCases) { Text($0.displayName).tag($0) }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                        }
                    }
                    section("iCloud Sync") {
                        row {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sync via iCloud").font(DL.Text.body17).foregroundStyle(DL.text)
                                Text("Mirror your medications to iPad and other iPhones via your private iCloud. Off by default — your data stays on this iPhone and Apple Watch.")
                                    .font(DL.Text.footnote13).foregroundStyle(DL.text2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                            Toggle("", isOn: $iCloudSyncEnabled)
                                .labelsHidden().tint(DLAccent.sage.color)
                                .onChange(of: iCloudSyncEnabled) { _, _ in pendingSyncChange = true }
                        }
                        if pendingSyncChange {
                            Divider().padding(.leading, 16)
                            row {
                                Text("Restart DoseLeft for this change to take effect.")
                                    .font(DL.Text.footnote13)
                                    .foregroundStyle(DLAccent.ochre.color)
                            }
                        }
                    }
                    section("Privacy") {
                        Text("By default, your medication data stays only on this iPhone and your Apple Watch — they talk directly over Bluetooth. Turning on iCloud Sync adds iPad/multi-device support; data is encrypted in transit and at rest. DoseLeft has no servers, no accounts, and no analytics.")
                            .font(DL.Text.subhead15)
                            .foregroundStyle(DL.text)
                            .padding(16)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    section("About") {
                        row {
                            Text("Version").font(DL.Text.body17).foregroundStyle(DL.text)
                            Spacer()
                            Text(Bundle.main.shortVersion)
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundStyle(DL.text2)
                        }
                        Divider().padding(.leading, 16)
                        row {
                            Text("Acknowledgments").font(DL.Text.body17).foregroundStyle(DL.text)
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(DL.text3)
                        }
                    }
                    Spacer(minLength: 40)
                }
            }
            .background(DL.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundStyle(DLAccent.lavender.color)
                }
            }
        }
    }

    @ViewBuilder
    private func section<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: 13, weight: .medium))
                .tracking(0.4)
                .foregroundStyle(DL.text2)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20).padding(.bottom, 8)
        VStack(spacing: 0, content: content)
            .background(DL.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func row<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        HStack(spacing: 12, content: content)
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .padding(.vertical, 6)
    }
}

private extension Bundle {
    var shortVersion: String {
        (object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "1.0.0"
    }
}
