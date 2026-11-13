import Core
import CoreUI
import DesignSystem
import SwiftUI

/// A saved note (CELLAR.md §5), in a sheet that is dragged down to close (CELLAR-R13): the wine as the Home's wine
/// sheet shows it, read only, with the photos after the name and the user's note after the maps. Edit opens the new note.
public struct NoteView<ViewModel: NoteViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    @State private var search: URL?

    private var model: NoteUIModel { viewModel.uiModel }
    private var resources: NoteResourcesUIModel { model.resources }

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if let content = model.content {
                    WineSheetBody(content: content, strings: WineSheetStrings(resources: resources.paper),
                                  onFindWine: nil,
                                  headerAccessory: { added },
                                  afterHeader: { photos })
                }
                if let note = model.note {
                    NotePaperNote(label: resources.paper.yourNoteText, text: note)
                        .padding(.top, 64)
                }
                end.padding(.top, 56)
            }
            .padding(.horizontal, 26)
            .padding(.top, 42)
            .padding(.bottom, 44)
        }
        .scrollIndicators(.hidden)
        .foregroundStyle(UVVAColor.mossDeep)
        .background(UVVAColor.parchment.ignoresSafeArea())
        // Dark status bar over the light paper.
        .preferredColorScheme(.light)
        .task { await viewModel.load() }
        .interactiveDismissDisabled(model.isWorking)
        .sheet(item: $search) { url in SafariSheet(url: url).ignoresSafeArea() }
        .sheet(isPresented: Binding(get: { model.isConfirmingDelete }, set: { if !$0 { viewModel.cancelDelete() } })) {
            NoteDeleteSheet(resources: resources, isWorking: model.isWorking,
                            onDelete: { Task { await viewModel.confirmDelete() } },
                            onCancel: viewModel.cancelDelete)
        }
    }

    /// "Added 29 Aug", under the producer.
    private var added: some View {
        Text(model.addedText)
            .font(UVVAFont.sans(11))
            .foregroundStyle(UVVAColor.mossDeep.opacity(0.62))
            .padding(.top, 8)
    }

    /// The labels, with the verdict on the front.
    @ViewBuilder private var photos: some View {
        if model.photoFront != nil || model.photoBack != nil {
            NoteCover(front: model.photoFront, back: model.photoBack, tag: model.coverTag)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.top, 28)
        }
    }

    private var end: some View {
        VStack(spacing: 0) {
            if let content = model.content {
                WineSheetButton(title: resources.paper.findWineText, style: .outlined) {
                    search = content.findURL
                }
                .padding(.bottom, 12)
            }
            HStack(spacing: 32) {
                linkButton(resources.editText) { viewModel.edit() }
                linkButton(resources.deleteText) { viewModel.askToDelete() }
            }
            if let error = model.errorText {
                Text(error).font(UVVAFont.sans(12)).opacity(0.74).padding(.top, 16)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func linkButton(_ text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text.uppercased())
                .font(UVVAFont.sans(9, .regular))
                .tracking(2.3)
                .opacity(0.7)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview {
    NoteView(viewModel: MockNoteViewModel())
}
#endif
