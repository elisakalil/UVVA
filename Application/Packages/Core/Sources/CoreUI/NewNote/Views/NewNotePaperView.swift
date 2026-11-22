#if os(iOS)
import Core
import DesignSystem
import SwiftUI

/// The wine and the user's additions, shared by the label reading and the Home's wine sheet.
struct NewNotePaperView: View {
    var model: NewNoteUIModel
    var onAnswer: (Bool) -> Void
    var onRate: (Verdict, Int?) -> Void
    var onNote: (String) -> Void
    var onAddChip: (String, NewNoteChipField) -> Void
    var loadChipOptions: (NewNoteChipField) async -> [String]
    var onIntensity: (Double, PalateAxis) -> Void
    var onReplacePhoto: (Data, NewNotePhotoSide) -> Void
    var onSave: () -> Void

    @State private var chipField: NewNoteChipField?
    @State private var isExplainingIntensity = false
    @State private var photoSide: NewNotePhotoSide?
    @State private var isRating = false

    private let ink = UVVAColor.mossDeep

    private var resources: NewNoteResourcesUIModel { model.resources }

    var body: some View {
        ScrollView {
            if let content = model.content {
                // From what the wine is to what the user adds: the name and photos, the certificate, the match and
                // the maps with what they show, the facts, the chips and the intensity. The rating is at the foot.
                VStack(alignment: .leading, spacing: NotePaper.sectionSpacing) {
                    VStack(alignment: .leading, spacing: 28) {
                        NotePaperTitle(title: content.title, producer: content.producer)
                        NotePhotoPair {
                            photo(model.photoFront, side: .front, label: resources.frontStepText)
                        } back: {
                            photo(model.photoBack, side: .back, label: resources.backStepText)
                        }
                    }
                    if let certificate = content.certificate {
                        WineCertificateCard(certificate: certificate)
                    }
                    NotePaperPersonal(match: content.match, insights: content.insights, profile: content.profile,
                                      palate: content.palate, shared: content.matchShared,
                                      apart: content.matchApart, resources: resources.paper)
                    NotePaperFacts(content: content, resources: resources.paper)
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach([NewNoteChipField.grapes, .notes, .pairings]) { field in
                            NotePaperChips(label: chipTitle(field), chips: content.chips(field),
                                           addLabel: resources.paper.addText(chipTitle(field))) {
                                chipField = field
                            }
                        }
                    }
                    NotePaperIntensity(title: resources.paper.intensityText, profile: content.profile,
                                       infoLabel: TastingGuideCopy.title,
                                       onInfo: { isExplainingIntensity = true }, onPick: onIntensity)
                    #if DEBUG
                    if let text = model.readingDebugText {
                        NewNoteReadingDebugView(text: text, export: model.readingExportText)
                    }
                    #endif
                }
                .padding(.horizontal, 26)
                .padding(.top, 42)
                .padding(.bottom, 24)
            }
        }
        .scrollIndicators(.hidden)
        // "Save note" stays at the foot while the paper scrolls under it.
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        .disabled(model.isWorking)
        .foregroundStyle(ink)
        .background(UVVAColor.parchment.ignoresSafeArea())
        .preferredColorScheme(.light)
        .sheet(item: $photoSide) { side in
            NewNotePhotoSheet(resources: resources) { data in
                onReplacePhoto(data, side)
            }
        }
        .sheet(isPresented: $isRating) {
            NoteRatingSheet(resources: resources.rating, verdict: model.currentVerdict, score: model.currentScore,
                            note: model.draftNote,
                            onSave: { verdict, score, note in
                                onRate(verdict, score)
                                onNote(note)
                                return true
                            },
                            onNotTasted: model.isRatedBefore || model.currentVerdict == nil ? nil : { onAnswer(false) })
        }
        .sheet(isPresented: $isExplainingIntensity) {
            NewNoteTastingGuide()
        }
        .sheet(item: $chipField) { field in
            NewNoteChipSheet(title: chipTitle(field), resources: resources,
                             existing: model.wine.map { field.values(in: $0) } ?? [],
                             loadOptions: { await loadChipOptions(field) }) { values in
                for value in values { onAddChip(value, field) }
            }
        }
    }

    /// The rating, outlined, over "Save note", both always there: unrated, the wine goes in as Not yet.
    private var footer: some View {
        VStack(spacing: 10) {
            if let error = model.errorText {
                Text(error).font(UVVAFont.sans(12)).opacity(0.74)
            }
            WineSheetButton(title: resources.rating.linkText(model.currentVerdict, score: model.currentScore),
                            style: .choice) {
                isRating = true
            }
            WineTastingActions(question: nil, primaryTitle: resources.saveNoteText,
                               isPrimaryEnabled: !model.isWorking) {
                onSave()
            }
        }
        .padding(.horizontal, 26)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .background {
            UVVAColor.parchment.ignoresSafeArea(edges: .bottom)
                // The paper fades into the foot instead of being cut by it.
                .overlay(alignment: .top) {
                    LinearGradient(colors: [UVVAColor.parchment.opacity(0), UVVAColor.parchment],
                                   startPoint: .top, endPoint: .bottom)
                        .frame(height: 24)
                        .offset(y: -24)
                        .allowsHitTesting(false)
                }
        }
    }

    /// The photo or vineyard placeholder. The front placeholder shows the add prompt.
    private func photo(_ data: Data?, side: NewNotePhotoSide, label: String) -> some View {
        Button {
            photoSide = side
        } label: {
            Color.clear
                .frame(height: 220)
                .overlay {
                    if let data, let image = UIImage(data: data) {
                        Image(uiImage: image).resizable().scaledToFill()
                    } else {
                        UVVAPhoto.background.resizable().scaledToFill()
                            .overlay {
                                if side == .front {
                                    NotePalette.veil.opacity(0.5)
                                    HStack(spacing: 8) {
                                        Text(resources.addPhotoText.uppercased())
                                            .font(UVVAFont.sans(10, .medium))
                                            .tracking(2.6)
                                        Image(systemName: resources.addPhotoIcon)
                                            .font(.system(size: 12, weight: .regular))
                                    }
                                    .foregroundStyle(UVVAColor.creamFill)
                                    .padding(.horizontal, 8)
                                }
                            }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(data == nil ? resources.addPhotoText : resources.changePhotoText)
        .accessibilityHint(label)
    }

    private func chipTitle(_ field: NewNoteChipField) -> String {
        switch field {
        case .grapes: resources.paper.grapesText
        case .notes: resources.paper.notesText
        case .pairings: resources.paper.pairingsText
        }
    }
}
#endif
