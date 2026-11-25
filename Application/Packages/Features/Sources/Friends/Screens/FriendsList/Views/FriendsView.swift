import Core
import CoreUI
import DesignSystem
import SwiftUI
import UIKit

/// The Friends tab (FRIENDS.md §4): "Your Friends" with the table button, Quick add across the page, the requests
/// and the friends. The table button turns the list into a choice of who comes (FRI-R18); "Search by name" fades in
/// once the page is scrolled, like the Cellar's search.
public struct FriendsView<ViewModel: FriendsViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    @Environment(\.openURL) private var openURL
    @FocusState private var isSearchFocused: Bool
    @State private var scrolled: CGFloat = 0
    @State private var headerHeight: CGFloat = 0
    @State private var position = ScrollPosition()
    /// The Cellar's new note, from "Add to cellar" on a wine a friend sent (FRI-R11c), or on a wine for the user and
    /// the friend(s), opened over the friend or the group table.
    @Binding private var newNote: NewNoteViewModel?

    private var model: FriendsUIModel { viewModel.uiModel }
    /// A friend or a group table is open over the tab: the new note is theirs to show.
    private var isCovered: Bool { viewModel.profile != nil || viewModel.groupTable != nil }
    private var resources: FriendsResourcesUIModel { model.resources }

    public init(viewModel: ViewModel, newNote: Binding<NewNoteViewModel?> = .constant(nil)) {
        self.viewModel = viewModel
        self._newNote = newNote
    }

    public var body: some View {
        ZStack(alignment: .top) {
            PageBackground(photo: UVVAPhoto.hills, veiled: true)
            content
            searchBar
                .opacity(searchOpacity)
                .allowsHitTesting(searchOpacity > 0.5)
                .accessibilityHidden(searchOpacity <= 0.5)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if model.isSelecting { selectionBar.transition(.move(edge: .bottom).combined(with: .opacity)) }
        }
        .animation(.easeOut(duration: 0.25), value: model.isSelecting)
        .animation(.easeOut(duration: 0.2), value: model.isSearching)
        .tabBarHidden(model.isSelecting)
        .foregroundStyle(UVVAColor.creamFill)
        // The glass shows the hills it scrolls over.
        .environment(\.glassPhoto, .hills)
        .overlay(alignment: .top) { toast }
        .animation(.easeOut(duration: 0.3), value: model.toastText)
        .onChange(of: model.toastText) { _, text in
            if let text { AccessibilityNotification.Announcement(text).post() }
        }
        .task { await viewModel.load() }
        .fullScreenCover(item: Binding(get: { viewModel.groupTable }, set: { if $0 == nil { viewModel.closeGroupTable() } })) { table in
            GroupTableView(viewModel: table, newNote: $newNote)
        }
        .fullScreenCover(item: Binding(get: { viewModel.profile }, set: { if $0 == nil { viewModel.closeFriend() } })) { profile in
            FriendProfileView(viewModel: profile, newNote: $newNote)
        }
        // FRI-R11c: a wine a friend sent, full screen; "Add to cellar" opens the new note once it is gone.
        .fullScreenCover(item: Binding(get: { model.receivedWine }, set: { if $0 == nil { viewModel.closeReceived() } }),
                         onDismiss: viewModel.receivedDismissed) { wine in
            FriendWineView(model: wine, onPrimary: viewModel.addReceivedToCellar, onClose: viewModel.closeReceived)
        }
        // Over a friend or a group table, the new note opens over them instead.
        .newNoteSheet(Binding(get: { isCovered ? nil : newNote }, set: { newNote = $0 }))
        .fullScreenCover(isPresented: Binding(get: { model.isInviting }, set: { if !$0 { viewModel.closeInvite() } })) {
            if let invite = model.invite { FriendsInviteView(invite: invite, onFinish: viewModel.closeInvite) }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                if model.isReady {
                    Group {
                        if model.isSearching { searchResults } else { list }
                    }
                    .padding(.top, 34)
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 32)
            .animation(.easeOut(duration: 0.25), value: model.isReady)
        }
        .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y + $0.contentInsets.top } action: { _, offset in
            scrolled = offset
        }
        .scrollDismissesKeyboard(.immediately)
        .scrollIndicators(.hidden)
        .scrollEdgeFade(12, throughBottomInset: true)
        .scrollPosition($position)
        .refreshable { await viewModel.reload() }
        .onChange(of: model.isSearching) { _, isSearching in
            if isSearching { position.scrollTo(edge: .top) }
        }
    }

    /// "Your Friends" and the table button; with no friend yet, what friends are for (FRI-R06).
    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                Text(resources.titleText)
                    .font(UVVAFont.sans(31, .ultraLight))
                    .tracking(-0.47)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityValue(model.friends.isEmpty ? "" : model.countText)
                Spacer()
                searchButton
                tableButton
            }
            if model.isEmpty {
                Text(resources.emptyBodyText)
                    .font(UVVAFont.sans(12.5))
                    .lineSpacing(3)
                    .opacity(0.76)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 288, alignment: .leading)
                    .padding(.horizontal, 4)
                    .padding(.top, 10)
            }
        }
        .padding(.top, 36)
        .padding(.bottom, 6)
        // The search bar comes down over the header: the title and its buttons step aside while it is open.
        .opacity(isSearchFocused || model.isSearching ? 0 : 1)
        .allowsHitTesting(!(isSearchFocused || model.isSearching))
        .animation(.easeOut(duration: 0.2), value: isSearchFocused)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { headerHeight = $0 }
    }

    /// Opens "Search by name" straight away, without scrolling the header out first.
    private var searchButton: some View {
        Button { isSearchFocused = true } label: {
            Image(systemName: resources.searchIcon)
                .font(.system(size: 21, weight: .ultraLight))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(resources.searchPromptText)
        // The same overflow as the table button beside it, so the two sit on one line.
        .padding(.vertical, -5)
        .padding(.trailing, -10)
    }

    /// The three figures at a table: starts the choice of who comes (FRI-R18), and ends it.
    /// Always there, so the tab looks the same from the first friend on; faded and inactive below two friends.
    private var tableButton: some View {
        Button(action: model.isSelecting ? viewModel.cancelSelecting : viewModel.startSelecting) {
            // FRI-R18: sky blue while choosing, like "Pick who’s coming…".
            UVVAIllustration.table
                .resizable()
                .scaledToFit()
                .frame(height: 20)
                .padding(.horizontal, 10)
                .frame(height: 34)
                .foregroundStyle(model.isSelecting ? UVVAColor.sky : UVVAColor.creamFill)
                .overlay(RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(model.isSelecting ? UVVAColor.sky.opacity(0.85) : UVVAColor.creamFill.opacity(0.24),
                                  lineWidth: 0.5))
                .opacity(model.isSelecting ? 1 : 0.92)
                .animation(.easeOut(duration: 0.25), value: model.isSelecting)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!canUseTable)
        .opacity(canUseTable ? 1 : 0.35)
        .animation(.easeOut(duration: 0.25), value: canUseTable)
        .accessibilityLabel(model.isSelecting ? resources.cancelText : resources.buildTableText)
        .accessibilityHint(canUseTable ? "" : resources.needTwoFriendsText)
        // The 44 pt touch area overflows the 34 pt frame, so the line under the title stays put when it appears.
        .padding(.vertical, -5)
    }

    private var canUseTable: Bool { model.canSelect || model.isSelecting }

    private var searchBar: some View {
        SearchField(text: Binding(get: { model.query }, set: { viewModel.updateQuery($0) }),
                    prompt: resources.searchPromptText,
                    isFocused: $isSearchFocused,
                    onCancel: {})
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
    }

    /// Search fades in after the header scrolls out of view and stays visible while in use.
    private var searchOpacity: Double {
        if isSearchFocused || model.isSearching { return 1 }
        return min(1, max(0, (scrolled - headerHeight) / 44))
    }

    /// Quick add, the requests and the friends (or the invite): shown once there is something real to show.
    private var list: some View {
        VStack(alignment: .leading, spacing: 0) {
            // FRI-R18: while choosing, what the choice is for, fading in where Quick add or the invite card was.
            if model.isSelecting {
                pickPrompt
                    .padding(.bottom, 26)
                    .transition(.opacity)
            // FRI-R07b: nobody to quick add, so an invite in a card in its place, close to the list.
            } else if showsInviteCard {
                FriendsInviteCard(text: resources.inviteFriendsText) {
                    Task { await viewModel.addFriends() }
                }
                .padding(.top, 20)
                .padding(.bottom, 14)
                .transition(.opacity)
            // FRI-R06: with no friend yet, Quick add shows only when a contact is already on UVVA.
            } else if !model.isEmpty || hasSuggestions {
                QuickAddSection(resources: resources, state: model.quickAdd,
                                onAdd: { id in Task { await viewModel.add(id) } },
                                onCancel: { id in Task { await viewModel.cancelRequest(id) } },
                                onDismiss: { id in perform { await viewModel.dismissSuggestion(id) } },
                                onAskAccess: { Task { await viewModel.askForContacts() } },
                                onOpenSettings: openSettings)
                    .padding(.bottom, 34)
                    .transition(.opacity)
            }
            if !model.isSelecting {
                if !model.requests.isEmpty {
                    requests.padding(.bottom, 26)
                }
                if !model.received.isEmpty {
                    received.padding(.bottom, 26)
                }
            }
            if model.isEmpty {
                if !model.isSelecting && !model.pending.isEmpty { pendingFriends }
                FriendsCompareCall(resources: resources, isDenied: model.quickAdd == .openSettings,
                                   onAdd: { Task { await viewModel.addFriends() } },
                                   onOpenSettings: openSettings)
                    .padding(.top, 70)
            } else {
                friends
                if !model.isSelecting && !model.pending.isEmpty { pendingFriends }
            }
        }
        // Rows that come and go do so with a fade.
        .animation(.easeOut(duration: 0.25), value: model.requests)
        .animation(.easeOut(duration: 0.25), value: model.received)
        .animation(.easeOut(duration: 0.25), value: model.friends)
        .animation(.easeOut(duration: 0.25), value: model.pending)
        .animation(.easeOut(duration: 0.25), value: model.quickAdd)
    }

    /// "Pick who’s coming…", in the brush lettering and the sky blue of the table button while choosing.
    private var pickPrompt: some View {
        Text(resources.pickPromptText.uppercased())
            .font(UVVAFont.redGrapes(15))
            .tracking(0.3)
            .lineSpacing(4)
            .foregroundStyle(UVVAColor.sky)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
    }

    /// FRI-R07b: with friends and nobody to quick add.
    private var showsInviteCard: Bool { !model.isEmpty && model.quickAdd == .noSuggestions }

    private var hasSuggestions: Bool {
        if case .suggestions = model.quickAdd { return true }
        return false
    }

    @ViewBuilder private var searchResults: some View {
        if model.friends.isEmpty {
            Text(resources.noMatchesText)
                .font(UVVAFont.sans(12.5))
                .opacity(0.76)
                .padding(.top, 8)
        } else {
            friends
        }
    }

    /// "Find a bottle for these [n]", over the bottom of the tab while choosing (FRI-R18).
    private var selectionBar: some View {
        VStack(spacing: 8) {
            if let full = model.tableFullText {
                Text(full).font(UVVAFont.sans(11)).opacity(0.75)
            }
            Button(action: viewModel.findBottle) {
                HStack(spacing: 14) {
                    Text(model.selectButtonText)
                        .font(UVVAFont.sans(12.5, .regular))
                        .tracking(0.75)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(verbatim: "›")
                        .font(UVVAFont.sans(20, .ultraLight))
                        .opacity(0.6)
                        .accessibilityHidden(true)
                }
                .foregroundStyle(UVVAColor.mossDeep)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(UVVAColor.creamFill.opacity(0.94), in: Capsule())
                .shadow(color: Color(hex: 0x0C1009).opacity(0.42), radius: 15, y: 12)
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!model.canFindBottle)
            .opacity(model.canFindBottle ? 1 : 0.4)
            .animation(.easeOut(duration: 0.2), value: model.canFindBottle)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var requests: some View {
        VStack(alignment: .leading, spacing: 0) {
            FriendsSectionLabel(text: resources.requestsText)
                .padding(.bottom, 4)
            ForEach(model.requests) { row in
                FriendRequestRow(resources: resources, row: row,
                                 onAccept: { perform { await viewModel.accept(row.id) } },
                                 onDecline: { perform { await viewModel.decline(row.id) } })
            }
        }
    }

    /// FRI-R11c: "Sent to you": each wine a friend sent, opening it full screen.
    private var received: some View {
        VStack(alignment: .leading, spacing: 0) {
            FriendsSectionLabel(text: resources.sentToYouText)
                .padding(.bottom, 4)
            ForEach(model.received) { row in
                Button { Task { await viewModel.openReceived(row.id) } } label: {
                    HStack(spacing: 14) {
                        FriendsPersonLabel(name: row.title, signature: row.wineName.uppercased())
                        Text(verbatim: "›")
                            .font(UVVAFont.sans(20, .ultraLight))
                            .opacity(0.4)
                            .accessibilityHidden(true)
                    }
                    .padding(.vertical, 15)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var friends: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(model.friends) { row in
                Button {
                    if model.isSelecting { viewModel.toggle(row.id) } else { viewModel.openFriend(row.id) }
                } label: {
                    FriendRow(row: row, isSelected: model.isSelecting ? model.selectedIDs.contains(row.id) : nil)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// FRI-R04b: who the user added or invited, faded under the friends until they are friends too. Not tappable:
    /// there is no map to open yet.
    private var pendingFriends: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(model.pending) { row in
                HStack(spacing: 14) {
                    FriendsPersonLabel(name: row.name, signature: row.statusText)
                }
                .padding(.vertical, 15)
                .opacity(0.45)
                .accessibilityElement(children: .combine)
            }
        }
    }

    /// "[name] is now your friend." over the top of the tab (FRI-R08a).
    @ViewBuilder private var toast: some View {
        if let text = model.toastText {
            Text(text)
                .font(UVVAFont.sans(12.5, .medium))
                .foregroundStyle(UVVAColor.mossDeep)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 20)
                .background(UVVAColor.creamFill, in: Capsule())
                .shadow(color: Color(hex: 0x0C100A).opacity(0.28), radius: 17, y: 14)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private func perform(_ action: @escaping () async -> Void) {
        Task { await action() }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
    }
}

#if DEBUG
#Preview("Friends") {
    FriendsView(viewModel: MockFriendsViewModel())
}

#Preview("Empty") {
    FriendsView(viewModel: MockFriendsViewModel(empty: true))
}
#endif
