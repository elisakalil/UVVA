#if os(iOS)
import Core
import DesignSystem
import PhotosUI
import SwiftUI

/// The photo at the top of the note, taken again or for the first time (CELLAR-R24): the camera in a label-shaped
/// frame, the shutter and, beside it, a photo from the library. Only the photo changes; the wine stays as read.
struct NewNotePhotoSheet: View {
    var resources: NewNoteResourcesUIModel
    var onPhoto: (Data) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var camera = LabelCamera()
    @State private var isTaking = false
    @State private var picked: PhotosPickerItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(resources.photoTitleText)
                        .font(UVVAFont.sans(26, .ultraLight))
                        .tracking(-0.4)
                        .accessibilityAddTraits(.isHeader)
                    Text(resources.photoBodyText)
                        .font(UVVAFont.sans(12.5))
                        .opacity(0.8)
                }
                Spacer(minLength: 12)
                Button { dismiss() } label: {
                    Image(systemName: resources.closeIcon)
                        .font(.system(size: 11))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(resources.closeText)
            }
            .padding(.leading, 30)
            .padding(.trailing, 16)
            .padding(.top, 40)

            viewfinder
                .padding(.horizontal, 40)
                .padding(.top, 26)
            Spacer(minLength: 16)
            foot
                .frame(maxWidth: .infinity)
                .frame(height: 96)
                .padding(.bottom, 24)
        }
        .foregroundStyle(UVVAColor.creamFill)
        .background(NotePalette.cameraGround.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
        .onAppear { camera.start() }
        .onDisappear { camera.stop() }
    }

    /// What the camera sees, inside the frame of a label.
    private var viewfinder: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(NotePalette.cameraGround)
            .overlay {
                if camera.isAvailable { LabelCameraPreview(session: camera.session) }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18).strokeBorder(UVVAColor.creamFill.opacity(0.9), lineWidth: 1)
            }
            .aspectRatio(310.0 / 430.0, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)
    }

    private var foot: some View {
        ZStack {
            if camera.isAvailable || LabelCameraSample.isAvailable {
                Button(action: shoot) {
                    Circle()
                        .strokeBorder(UVVAColor.creamFill, lineWidth: 1.5)
                        .frame(width: 72, height: 72)
                        .overlay {
                            Circle().fill(UVVAColor.creamFill).frame(width: 58, height: 58).opacity(isTaking ? 0.6 : 1)
                        }
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(isTaking)
                .accessibilityLabel(resources.shutterText)
            } else {
                Text(resources.cameraUnavailableText).font(UVVAFont.sans(12)).opacity(0.7)
            }
            PhotosPicker(selection: $picked, matching: .images) {
                Image(systemName: resources.libraryIcon)
                    .font(.system(size: 17, weight: .light))
                    .frame(width: 48, height: 48)
                    .overlay { Circle().strokeBorder(UVVAColor.creamFill.opacity(0.55), lineWidth: 0.5) }
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(isTaking)
            .accessibilityLabel(resources.libraryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 40)
        }
        .onChange(of: picked) { _, item in
            guard let item else { return }
            picked = nil
            choose(item)
        }
    }

    /// The chosen photo, shrunk like one from the camera, off the main thread.
    private func choose(_ item: PhotosPickerItem) {
        isTaking = true
        Task {
            let data = try? await item.loadTransferable(type: Data.self)
            let photo: Data? = if let data { await Task.detached { LabelCamera.shrink(data) }.value } else { nil }
            finish(photo)
        }
    }

    private func shoot() {
        isTaking = true
        Task {
            let data = camera.isAvailable ? await camera.takePhoto() : LabelCameraSample.photo(.front)
            // Only kept, never read: shrunk like any kept photo.
            let photo: Data? = if let data { await Task.detached { LabelCamera.shrink(data) }.value } else { nil }
            finish(photo)
        }
    }

    private func finish(_ photo: Data?) {
        isTaking = false
        guard let photo else { return }
        onPhoto(photo)
        dismiss()
    }
}
#endif
