import Core
import Match
import CoreUI
import DesignSystem
import SwiftUI

/// A saved note (CELLAR.md §5), in a sheet that is dragged down to close (CELLAR-R13), in one of two orders
/// (CELLAR-R26): with photos, they come under the name; without, the match leads. The rating and Edit stay at the
/// foot; Edit opens the new note.
public struct NoteView<ViewModel: NoteViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    private var frontPreview: UIImage?
    @State private var search: URL?
    @State private var isRating = false

    private var model: NoteUIModel { viewModel.uiModel }
    private var resources: NoteResourcesUIModel { model.resources }

    public init(viewModel: ViewModel) {
        self.init(viewModel: viewModel, frontPreview: nil)
    }

    init(viewModel: ViewModel, frontPreview: UIImage?) {
        self.viewModel = viewModel
        self.frontPreview = frontPreview
    }

    public var body: some View {
        ScrollView {
            if let content = model.content {
                VStack(alignment: .leading, spacing: NotePaper.sectionSpacing) {
                    if hasPhotos { withPhotos(content) } else { withoutPhotos(content) }
                }
                .padding(.horizontal, 26)
                .padding(.top, 42)
                .padding(.bottom, 24)
            }
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        .foregroundStyle(UVVAColor.mossDeep)
        .background(UVVAColor.parchment.ignoresSafeArea())
        // Dark status bar over the light paper.
        .preferredColorScheme(.light)
        .task { await viewModel.load() }
        .interactiveDismissDisabled(model.isWorking)
        .sheet(item: $search) { url in SafariSheet(url: url).ignoresSafeArea() }
        .sheet(isPresented: $isRating) {
            NoteRatingSheet(resources: resources.rating, verdict: model.verdict, score: model.score,
                            note: model.note ?? "", errorText: model.errorText) { verdict, score, note in
                await viewModel.rate(verdict, score: score, note: note)
            }
        }
        .sheet(isPresented: Binding(get: { model.isConfirmingDelete }, set: { if !$0 { viewModel.cancelDelete() } })) {
            NoteDeleteSheet(resources: resources, isWorking: model.isWorking,
                            onDelete: { Task { await viewModel.confirmDelete() } },
                            onCancel: viewModel.cancelDelete)
        }
    }

    /// The photos are kept, or still being read with the label already seen in the Cellar: the order stays the
    /// same while they arrive.
    private var hasPhotos: Bool {
        model.photoFront != nil || model.photoBack != nil || (model.isReadingPhotos && frontPreview != nil)
    }

    /// With photos (CELLAR-R26): the name and the photos, the certificate, the facts, the match and the maps, the
    /// intensity and the user's note.
    @ViewBuilder private func withPhotos(_ content: WineSheetContent) -> some View {
        VStack(alignment: .leading, spacing: 28) {
            title(content)
            NoteCover(front: model.photoFront, back: model.photoBack, tag: model.coverTag,
                      frontPreview: frontPreview, isReading: model.isReadingPhotos)
        }
        certificate(content)
        facts(content)
        VStack(alignment: .leading, spacing: 28) {
            match(content)
            maps(content)
        }
        intensity(content)
        yourNote
    }

    /// Without photos (CELLAR-R26): the name, the match and what it rests on, the certificate, the facts, the
    /// intensity, the maps and the user's note.
    @ViewBuilder private func withoutPhotos(_ content: WineSheetContent) -> some View {
        title(content)
        VStack(alignment: .leading, spacing: 14) {
            match(content)
            NotePaperMatchReasons(shared: content.sharedLine, apart: content.apartLine)
        }
        certificate(content)
        facts(content)
        intensity(content)
        maps(content)
        yourNote
    }

    private func title(_ content: WineSheetContent) -> some View {
        NotePaperTitle(title: content.title, producer: content.eyebrow, detail: model.addedText)
    }

    @ViewBuilder private func certificate(_ content: WineSheetContent) -> some View {
        if let certificate = content.certificate {
            WineCertificateCard(certificate: certificate)
        }
    }

    /// The facts, the pairings and how to serve it.
    private func facts(_ content: WineSheetContent) -> some View {
        WineSheetFacts(content: content, strings: WineSheetStrings(resources: resources.paper), spacing: 24,
                       standaloneFactLabels: [resources.paper.grapesText, resources.paper.notesText])
    }

    private func maps(_ content: WineSheetContent) -> some View {
        WineMapCarousel(copy: .init(wineTitle: resources.paper.wineMapText,
                                    comparisonTitle: resources.paper.comparisonText,
                                    wineLegend: resources.paper.wineText,
                                    palateLegend: resources.paper.palateText,
                                    overlapLegend: resources.paper.overlapText),
                        labels: PalateAxis.allCases.map(\.label), wine: content.profile.chartValues,
                        palate: content.palate?.chartValues, tint: NotePaper.ink)
    }

    /// The axes in dots, close together, as the wine sheet draws them.
    private func intensity(_ content: WineSheetContent) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(PalateAxis.allCases, id: \.self) { axis in
                let level = MapReading.level(content.profile, axis)
                PalateReadingLine(name: axis.label, level: level,
                                  word: MapReading.levelWord(level, on: axis), isStrong: true)
            }
        }
    }

    @ViewBuilder private var yourNote: some View {
        if let note = model.note {
            NotePaperNote(label: resources.paper.yourNoteText, text: note)
        }
    }

    /// "72% match with your map", alone: the maps under it show the rest.
    private func match(_ content: WineSheetContent) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            if let percentage = content.percentage {
                Text(percentage)
                    .font(UVVAFont.sans(44, .ultraLight))
                    .tracking(-1.3)
            }
            Text(content.percentageCaption)
                .font(UVVAFont.sans(12.5))
                .foregroundStyle(NotePaper.ink.opacity(0.78))
        }
        .accessibilityElement(children: .combine)
    }

    /// Fixed at the foot, the paper fading under it: the rating, outlined, and under it the search for the wine,
    /// Edit and Delete, the two small ones as icons.
    private var footer: some View {
        let isBusy = model.isReadingPhotos || model.isWorking
        return VStack(spacing: 10) {
            if let error = model.errorText, !isRating {
                Text(error).font(UVVAFont.sans(12)).opacity(0.74)
            }
            WineSheetButton(title: resources.rating.linkText(model.verdict, score: model.score), style: .choice) {
                isRating = true
            }
            .disabled(isBusy)
            HStack(spacing: 10) {
                iconButton(resources.findIcon, label: resources.paper.findWineText) {
                    search = model.content?.findURL
                }
                .disabled(model.content?.findURL == nil)
                WineTastingActions(question: nil, primaryTitle: resources.editText, isPrimaryEnabled: !isBusy) {
                    viewModel.edit()
                }
                iconButton(resources.deleteIcon, label: resources.deleteText) { viewModel.askToDelete() }
                    .disabled(model.isWorking)
            }
        }
        .padding(.horizontal, 26)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .background {
            UVVAColor.parchment.ignoresSafeArea(edges: .bottom)
                .overlay(alignment: .top) {
                    LinearGradient(colors: [UVVAColor.parchment.opacity(0), UVVAColor.parchment],
                                   startPoint: .top, endPoint: .bottom)
                        .frame(height: 24)
                        .offset(y: -24)
                        .allowsHitTesting(false)
                }
        }
    }

    /// A round outlined button with only an icon, the size of the main button's height.
    private func iconButton(_ icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .regular))
                .frame(width: 45, height: 45)
                .overlay { Circle().strokeBorder(UVVAColor.mossDeep.opacity(0.5), lineWidth: 0.5) }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

#if DEBUG
#Preview {
    NoteView(viewModel: MockNoteViewModel())
}
#endif
