import DesignSystem
import SwiftUI

/// Contacts (ONB-R37): who is on UVVA, who to invite, an A–Z bar, a search bar once scrolled and "Next".
struct ContactsView<ViewModel: ContactsViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    @State private var inviting: ContactRowUIModel?
    @State private var scrolled = false
    @FocusState private var searching: Bool

    /// How far the list scrolls before the search bar comes down.
    static var searchReveal: CGFloat { 40 }
    /// Room between the top of the screen and the search bar.
    static var searchTop: CGFloat { 32 }
    /// The list is hidden down to the foot of the bar, then fades back in below it.
    static var searchClear: CGFloat { searchTop + 44 }
    static var searchFade: CGFloat { 40 }
    /// The list also fades out at its foot, just above "Next".
    static var footFade: CGFloat { 48 }

    /// The search bar shows once the list is scrolled, and stays while it is in use.
    private var showsSearch: Bool { scrolled || searching || !viewModel.uiModel.query.isEmpty }

    var body: some View {
        let model = viewModel.uiModel
        ZStack(alignment: .bottom) {
            if model.isLoading {
                GrapeLoop().frame(width: 60, height: 84)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        ZStack {
                            HStack { BackChevron { viewModel.back() }; Spacer() }
                            if let title = model.title {
                                Text(title.uppercased())
                                    .font(UVVAFont.sans(10)).tracking(3).opacity(0.8)
                            }
                        }
                        .padding(.horizontal, 24)

                        if model.noResults {
                            Text(viewModel.uiModel.noResultsMessage)
                                .font(UVVAFont.sans(13))
                                .opacity(0.6)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                                .padding(.top, 80)
                        } else if !model.isLoading {
                            if !model.onUVVA.isEmpty {
                                section(image: model.accountsIllustration, title: model.onUVVATitle, rows: model.onUVVA)
                                    .padding(.top, 30)
                            }
                            if !model.toInvite.isEmpty {
                                section(image: model.inviteIllustration, title: viewModel.uiModel.inviteContactsWhoArenTOnText,
                                        rows: model.toInvite)
                                    .padding(.top, model.onUVVA.isEmpty ? 30 : 48)
                            }
                        }
                    }
                    // Room for the last row to clear the fade at the foot.
                    .padding(.bottom, Self.footFade)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.immediately)
                // The list fades out into the photo itself: at the top, under the search bar once it is down,
                // and at the foot, above "Next".
                .mask {
                    VStack(spacing: 0) {
                        Color.clear.frame(height: showsSearch && !model.isLoading ? Self.searchClear : 0)
                        LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                            .frame(height: showsSearch && !model.isLoading ? Self.searchFade : 24)
                        Color.black
                        LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                            .frame(height: Self.footFade)
                    }
                }
                .onScrollGeometryChange(for: Bool.self) { geometry in
                    geometry.contentOffset.y + geometry.contentInsets.top > Self.searchReveal
                } action: { _, isScrolled in
                    withAnimation(.smooth(duration: 0.25)) { scrolled = isScrolled }
                }
                .overlay(alignment: .top) {
                    if showsSearch && !model.isLoading {
                        SearchField(text: Binding(get: { viewModel.uiModel.query }, set: { viewModel.updateQuery($0) }),
                                    prompt: viewModel.uiModel.searchContactsText,
                                    isFocused: $searching, onCancel: {})
                            .padding(.horizontal, 24)
                            .padding(.top, Self.searchTop)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .overlay(alignment: .trailing) {
                    AlphabetIndex(letters: model.letters) { letter in
                        withAnimation { proxy.scrollTo("letter-\(letter)", anchor: .top) }
                    }
                    .padding(.trailing, 6)
                }
                // Fixed at the foot of the screen; the list ends just above it.
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    ActionButton(viewModel.uiModel.nextText, action: viewModel.finishContacts)
                        .shadow(color: Color(hex: 0x12180E).opacity(0.45), radius: 15, y: 10)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 12)
                }
            }
        }
        .task { await viewModel.loadContacts() }
        .sheet(item: $inviting) { row in
            if let link = viewModel.uiModel.inviteLink {
                ActivityShareSheet(message: viewModel.uiModel.inviteMessage, link: link) { inviting = nil }
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private func section(image: Image, title: String, rows: [ContactRowUIModel]) -> some View {
        VStack(spacing: 0) {
            image.resizable().scaledToFit().frame(width: 60, height: 84)
            Text(title)
                .font(UVVAFont.sans(18, .ultraLight))
                .tracking(-0.2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 22)
            if !rows.isEmpty {
                VStack(spacing: 0) {
                    ForEach(rows) { row in
                        ContactRow(row: row) { tap(row) }
                            .id(row.state == .invite || row.state == .invited ? firstOfLetter(row, in: rows) : row.id)
                    }
                }
                .padding(.leading, 20)
                .padding(.trailing, 34)
                .padding(.top, 14)
            }
        }
    }

    /// Rows to invite carry the id of their letter when they are the first with it, for the A–Z bar.
    private func firstOfLetter(_ row: ContactRowUIModel, in rows: [ContactRowUIModel]) -> String {
        rows.first { $0.letter == row.letter }?.id == row.id ? "letter-\(row.letter)" : row.id
    }

    private func tap(_ row: ContactRowUIModel) {
        switch row.state {
        case .add: Task { await viewModel.add(row.id) }
        case .invite, .invited:
            viewModel.markInvited(row.id)
            inviting = row
        case .requested: break
        }
    }
}
