import DesignSystem
import SwiftUI

/// Settings (YOU-R14 to R27). Language (YOU-R15a) waits for the pt-BR texts.
struct SettingsTabView<ViewModel: SettingsViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel

    @State private var editingName = false
    @State private var editingPhone = false
    @State private var editingPhoto = false
    @State private var editingReminder = false
    @State private var showingCertificates = false
    @State private var confirming: ConfirmKind?

    var body: some View {
        let model = viewModel.uiModel
        VStack(spacing: 14) {
            YouPanel {
                VStack(spacing: 0) {
                    SettingsRow(viewModel.uiModel.nameText, value: model.name, isFirst: true) { editingName = true }
                    SettingsRow(viewModel.uiModel.signedInWithText, value: model.signedInWith)
                    SettingsRow(viewModel.uiModel.phoneNumberText, value: model.phone) { editingPhone = true }
                    SettingsRow(model.profilePhotoText, action: { editingPhoto = true }) {
                        Avatar(photo: model.photo, size: 28)
                            .overlay(Circle().strokeBorder(UVVAColor.creamFill.opacity(0.45), lineWidth: 0.5))
                    }
                    SettingsRow(viewModel.uiModel.dailyReminderText, value: model.reminder) { editingReminder = true }
                }
            }

            YouPanel {
                VStack(alignment: .leading, spacing: 0) {
                    Text(viewModel.uiModel.sharedWithFriendsText.uppercased())
                        .font(UVVAFont.redGrapes(16)).tracking(0.64)
                    Text(viewModel.uiModel.whatYouHaveBuiltInText)
                        .font(UVVAFont.sans(12.5)).lineSpacing(5).opacity(0.84)
                        .padding(.top, 8)
                    VStack(spacing: 0) {
                        SettingsRow(viewModel.uiModel.myMapText, value: model.mapVisibility, isFirst: true)
                        SettingsRow(viewModel.uiModel.tablesText, value: model.tables)
                        SettingsRow(viewModel.uiModel.certificatesText, value: model.certificates,
                                    action: model.canOpenCertificates ? { showingCertificates = true } : nil)
                    }
                    .padding(.top, 10)
                }
            }

            Toggle(isOn: Binding(get: { model.mapIsPublic },
                                 set: { value in Task { await viewModel.setMapPublic(value) } })) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(viewModel.uiModel.makeChartPublicText).font(UVVAFont.sans(14))
                    Text(model.mapPublicNote).font(UVVAFont.sans(12)).lineSpacing(4).opacity(0.8)
                }
            }
            .tint(UVVAColor.creamFill)
            .padding(.horizontal, 6)
            .padding(.top, 10)

            if let notice = viewModel.uiModel.notice {
                Text(notice).font(UVVAFont.sans(12)).opacity(0.8).multilineTextAlignment(.center)
            }

            ActionButton(viewModel.uiModel.signOutText, style: .outline) { open(.signOut) }
                .padding(.top, 10)
            TextAction(viewModel.uiModel.deleteMyAccountText, opacity: 0.55) { open(.delete) }
        }
        .sheet(isPresented: $editingName) {
            EditNameView(viewModel: viewModel.editName)
        }
        .sheet(isPresented: $editingPhone) {
            EditPhoneView(viewModel: viewModel.editPhone)
        }
        .sheet(isPresented: $editingPhoto) {
            EditPhotoView(viewModel: viewModel.editPhoto)
        }
        .sheet(isPresented: $editingReminder) {
            ReminderView(viewModel: viewModel.reminder)
        }
        .fullScreenCover(isPresented: $showingCertificates) {
            CertificatesView(viewModel: viewModel.certificates, onClose: { showingCertificates = false })
        }
        .sheet(item: $confirming) { kind in
            ConfirmSheet(kind: kind, isWorking: viewModel.uiModel.isWorking) {
                switch kind {
                case .signOut: await viewModel.signOut()
                // A failed delete closes the sheet too: the card at the foot of the screen says so (YOU-R27).
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

    /// A failure card from the last try leaves as the next confirmation opens.
    private func open(_ kind: ConfirmKind) {
        viewModel.dismissDeleteFailure()
        confirming = kind
    }
}
