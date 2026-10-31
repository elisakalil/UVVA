import DesignSystem
import SwiftUI

/// Contacts (ONB-R37): who is on UVVA, who to invite, an A–Z bar, a search bar once scrolled and "Next".
struct ContactsView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var inviting: ContactRowUIModel?
    @State private var scrolled = false
    @FocusState private var searching: Bool

    /// How far the list scrolls before the search bar comes down.
    static let searchReveal: CGFloat = 40

    /// The search bar shows once the list is scrolled, and stays while it is in use.
    private var showsSearch: Bool { scrolled || searching || !viewModel.contactsQuery.isEmpty }

    var body: some View {
        let model = viewModel.contactsModel
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
                            Text("No contacts match “\(viewModel.contactsQuery)”", bundle: .module)
                                .font(UVVAFont.sans(13))
                                .opacity(0.6)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                                .padding(.top, 80)
                        } else if !model.isLoading {
                            if !model.onUVVA.isEmpty {
                                section(grape: 3, title: model.onUVVATitle, rows: model.onUVVA)
                                    .padding(.top, 30)
                            }
                            if !model.toInvite.isEmpty {
                                section(grape: 5, title: String(localized: "Invite contacts who aren't on UVVA", bundle: .module),
                                        rows: model.toInvite)
                                    .padding(.top, model.onUVVA.isEmpty ? 30 : 48)
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.immediately)
                .scrollEdgeFade()
                .onScrollGeometryChange(for: Bool.self) { geometry in
                    geometry.contentOffset.y + geometry.contentInsets.top > Self.searchReveal
                } action: { _, isScrolled in
                    withAnimation(.smooth(duration: 0.25)) { scrolled = isScrolled }
                }
                .overlay(alignment: .top) {
                    if showsSearch && !model.isLoading {
                        SearchField(text: $viewModel.contactsQuery,
                                    prompt: String(localized: "Search contacts", bundle: .module),
                                    isFocused: $searching, onCancel: {})
                            .padding(.horizontal, 24)
                            .padding(.top, 4)
                            .padding(.bottom, 18)
                            .background {
                                // The list fades out under the bar instead of running into it.
                                LinearGradient(colors: [UVVAColor.moss.opacity(0.92), UVVAColor.moss.opacity(0)],
                                               startPoint: .top, endPoint: .bottom)
                                    .ignoresSafeArea(edges: .top)
                                    .allowsHitTesting(false)
                            }
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
                    ActionButton(String(localized: "Next", bundle: .module), action: viewModel.finishContacts)
                        .shadow(color: Color(hex: 0x12180E).opacity(0.45), radius: 15, y: 10)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 12)
                }
            }
        }
        .sheet(item: $inviting) { row in
            if let link = viewModel.inviteLink {
                ActivityShareSheet(message: viewModel.inviteMessage, link: link) { inviting = nil }
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private func section(grape: Int, title: String, rows: [ContactRowUIModel]) -> some View {
        VStack(spacing: 0) {
            UVVAIllustration.grape(grape).resizable().scaledToFit().frame(width: 60, height: 84)
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
                .overlay(alignment: .top) { Rectangle().opacity(0.18).frame(height: 0.5) }
                .padding(.leading, 20)
                .padding(.trailing, 34)
                .padding(.top, 26)
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
