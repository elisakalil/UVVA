import DesignSystem
import PhotosUI
import SwiftUI

/// Change photo (YOU-R14a): a sheet with the photo large, a new one from the library, or none.
/// It leaves with a drag down; nothing changes until Save.
struct EditPhotoView<ViewModel: EditPhotoViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var pickingPhoto = false
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        let model = viewModel.uiModel
        YouSheet(title: model.changePhotoText, message: model.thePhotoNextToYourText, height: 540) {
            Spacer(minLength: 16)
            VStack(spacing: 10) {
                Button { pickingPhoto = true } label: {
                    Avatar(photo: model.photo, size: 160)
                        .overlay(Circle().strokeBorder(UVVAColor.creamFill.opacity(0.45), lineWidth: 0.5))
                        .opacity(model.isLoading ? 0.35 : 1)
                        // The photo is read and washed: the grape bunches, never a spinner.
                        .overlay { if model.isLoading { GrapeLoop().frame(width: 50, height: 70).transition(.opacity) } }
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(model.isLoading)
                .accessibilityLabel(model.choosePhotoText)
                // Always in the layout, so the photo does not jump when it is removed.
                TextAction(model.removePhotoText, opacity: 0.55) { viewModel.removePhoto() }
                    .opacity(model.hasPhoto ? 1 : 0)
                    .disabled(!model.hasPhoto || model.isLoading)
                    .accessibilityHidden(!model.hasPhoto)
            }
            .frame(maxWidth: .infinity)
            .animation(.easeOut(duration: 0.2), value: model.photo)
            .animation(.easeOut(duration: 0.2), value: model.isLoading)
            Spacer(minLength: 16)

            if let notice = model.notice {
                Text(notice).font(UVVAFont.sans(12)).multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity).padding(.bottom, 14)
            }
            ActionButton(model.choosePhotoText, style: .outline, isEnabled: !model.isLoading) { pickingPhoto = true }
            ActionButton(model.saveText, isEnabled: model.canSave) {
                Task { if await viewModel.savePhoto(model.photo) { dismiss() } }
            }
            .padding(.top, 10)
        }
        .photosPicker(isPresented: $pickingPhoto, selection: $photoItem, matching: .images)
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task {
                await viewModel.pickPhoto { try? await item.loadTransferable(type: Data.self) }
                photoItem = nil
            }
        }
        .onAppear { viewModel.prepare() }
    }
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        EditPhotoView(viewModel: EditPhotoPreviewViewModel())
    }
}

@MainActor
private final class EditPhotoPreviewViewModel: EditPhotoViewModelProtocol {
    @Published var uiModel = EditPhotoUIModel()
    func prepare() {}
    func pickPhoto(loading load: @Sendable () async -> Data?) async { uiModel.photo = await load() }
    func removePhoto() { uiModel.photo = nil }
    func savePhoto(_ photo: Data?) async -> Bool { true }
}
