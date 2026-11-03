import DesignSystem
import PhotosUI
import SwiftUI

/// Settings (YOU-R14 to R27). Language (YOU-R15a) waits for the pt-BR texts.
struct SettingsTabView: View {
    var viewModel: YouViewModel

    @State private var editingName = false
    @State private var editingPhone = false
    @State private var editingReminder = false
    @State private var showingCertificates = false
    @State private var confirming: ConfirmKind?
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        let model = viewModel.settings
        VStack(spacing: 14) {
            YouPanel {
                VStack(spacing: 0) {
                    SettingsRow(String(localized: "Name", bundle: .module), value: model.name, isFirst: true) { editingName = true }
                    SettingsRow(String(localized: "Signed in with", bundle: .module), value: model.signedInWith)
                    SettingsRow(String(localized: "Phone number", bundle: .module), value: model.phone) { editingPhone = true }
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        SettingsRow(String(localized: "Profile photo", bundle: .module)) {
                            Avatar(photo: model.photo, size: 28)
                                .overlay(Circle().strokeBorder(UVVAColor.creamFill.opacity(0.45), lineWidth: 0.5))
                        }
                        .allowsHitTesting(false)
                    }
                    .buttonStyle(.plain)
                    SettingsRow(String(localized: "Daily reminder", bundle: .module), value: model.reminder) { editingReminder = true }
                }
            }

            YouPanel {
                VStack(alignment: .leading, spacing: 0) {
                    Text(String(localized: "Shared with friends", bundle: .module).uppercased())
                        .font(UVVAFont.redGrapes(16)).tracking(0.64)
                    Text("What you have built in UVVA, ready to share.", bundle: .module)
                        .font(UVVAFont.sans(12.5)).lineSpacing(5).opacity(0.84)
                        .padding(.top, 8)
                    VStack(spacing: 0) {
                        SettingsRow(String(localized: "My Map", bundle: .module), value: model.mapVisibility, isFirst: true)
                        SettingsRow(String(localized: "Tables", bundle: .module), value: model.tables)
                        SettingsRow(String(localized: "Certificates", bundle: .module), value: model.certificates) {
                            showingCertificates = true
                        }
                    }
                    .padding(.top, 10)
                }
            }

            Toggle(isOn: Binding(get: { model.mapIsPublic },
                                 set: { value in Task { await viewModel.setMapPublic(value) } })) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Make chart public", bundle: .module).font(UVVAFont.sans(14))
                    Text(model.mapPublicNote).font(UVVAFont.sans(12)).lineSpacing(4).opacity(0.8)
                }
            }
            .tint(UVVAColor.creamFill)
            .padding(.horizontal, 6)
            .padding(.top, 10)

            if let notice = viewModel.notice {
                Text(notice).font(UVVAFont.sans(12)).opacity(0.8).multilineTextAlignment(.center)
            }

            ActionButton(String(localized: "Sign out", bundle: .module), style: .outline) { confirming = .signOut }
                .padding(.top, 10)
            TextAction(String(localized: "Delete my account", bundle: .module), opacity: 0.55) { confirming = .delete }
        }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let jpeg = PhotoResizer.squareJPEG(data) {
                    await viewModel.savePhoto(jpeg)
                }
                photoItem = nil
            }
        }
        .sheet(isPresented: $editingName) {
            EditNameView(name: model.name) { name in await viewModel.saveName(name) }
        }
        .sheet(isPresented: $editingPhone) {
            EditPhoneView(country: viewModel.phoneParts.country, national: viewModel.phoneParts.national) { national, country in
                await viewModel.savePhone(national: national, country: country)
            }
        }
        .fullScreenCover(isPresented: $editingReminder) {
            ReminderView(reminder: viewModel.reminder) { reminder in await viewModel.saveReminder(reminder) }
        }
        .fullScreenCover(isPresented: $showingCertificates) {
            CertificatesView(rows: viewModel.certificateRows, onOpen: { courseID in
                showingCertificates = false
                viewModel.openCertificate(courseID)
            }, onStartLearning: {
                showingCertificates = false
                viewModel.openLearn()
            })
        }
        .sheet(item: $confirming) { kind in
            ConfirmSheet(kind: kind, isWorking: viewModel.isWorking) {
                switch kind {
                case .signOut: await viewModel.signOut()
                case .delete: await viewModel.deleteAccount()
                }
                confirming = nil
            } onCancel: {
                confirming = nil
            }
            .presentationDetents([.height(360)])
            .presentationBackground(.clear)
        }
    }
}
