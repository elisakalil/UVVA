import Core
import DesignSystem
import SwiftUI
import UIKit

/// The Friends tab (FRIENDS.md §4): "Friends", the requests, the friends and Quick add.
public struct FriendsView<ViewModel: FriendsViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    @Environment(\.openURL) private var openURL

    private var model: FriendsUIModel { viewModel.uiModel }
    private var resources: FriendsResourcesUIModel { model.resources }

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack(alignment: .top) {
            PageBackground(blur: 2, veiled: true)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    if model.isReady { list.transition(.opacity) }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 32)
                .animation(.easeOut(duration: 0.25), value: model.isReady)
            }
            .scrollIndicators(.hidden)
            .refreshable { await viewModel.reload() }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if model.isSelecting { selectionBar.transition(.move(edge: .bottom).combined(with: .opacity)) }
        }
        .animation(.easeOut(duration: 0.25), value: model.isSelecting)
        .foregroundStyle(UVVAColor.creamFill)
        .overlay(alignment: .top) { toast }
        .animation(.easeOut(duration: 0.3), value: model.toastText)
        .onChange(of: model.toastText) { _, text in
            if let text { AccessibilityNotification.Announcement(text).post() }
        }
        .task { await viewModel.load() }
        .fullScreenCover(item: Binding(get: { viewModel.groupTable }, set: { if $0 == nil { viewModel.closeGroupTable() } })) { table in
            GroupTableView(viewModel: table)
        }
        .fullScreenCover(item: Binding(get: { viewModel.profile }, set: { if $0 == nil { viewModel.closeFriend() } })) { profile in
            FriendProfileView(viewModel: profile)
        }
        .fullScreenCover(isPresented: Binding(get: { model.isInviting }, set: { if !$0 { viewModel.closeInvite() } })) {
            if let invite = model.invite { FriendsInviteView(invite: invite, onFinish: viewModel.closeInvite) }
        }
    }

    /// The requests, the friends (or the invite) and Quick add: shown once there is something real to show.
    private var list: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !model.requests.isEmpty && !model.isSelecting { requests.padding(.bottom, 18) }
            if model.isEmpty {
                FriendsEmptyView(resources: resources, canInvite: model.invite != nil) { viewModel.openInvite() }
                    .padding(.top, 18)
            } else {
                friends
            }
            if !model.isSelecting {
                QuickAddSection(resources: resources, state: model.quickAdd,
                                onAdd: { id in Task { await viewModel.add(id) } },
                                onCancel: { id in Task { await viewModel.cancelRequest(id) } },
                                onDismiss: { id in perform { await viewModel.dismissSuggestion(id) } },
                                onAskAccess: { Task { await viewModel.askForContacts() } },
                                onOpenSettings: openSettings)
                    .padding(.top, 26)
            }
        }
        // Rows that come and go do so with a fade.
        .animation(.easeOut(duration: 0.25), value: model.requests)
        .animation(.easeOut(duration: 0.25), value: model.friends)
        .animation(.easeOut(duration: 0.25), value: model.quickAdd)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(resources.titleText)
                .font(UVVAFont.sans(31, .ultraLight))
                .tracking(-0.47)
                .accessibilityAddTraits(.isHeader)
            HStack(alignment: .firstTextBaseline) {
                if !model.friends.isEmpty {
                    Eyebrow(text: model.countText)
                }
                Spacer()
                if model.isSelecting {
                    TextAction(resources.cancelText, opacity: 0.8, action: viewModel.cancelSelecting)
                } else if model.canSelect {
                    hosting
                }
            }
        }
        .padding(.top, 36)
        .padding(.bottom, 14)
    }

    /// "Hosting tonight? · Select" (FRI-R18).
    private var hosting: some View {
        Button(action: viewModel.startSelecting) {
            HStack(spacing: 6) {
                Text(resources.hostingText).opacity(0.7)
                Text(verbatim: "·").opacity(0.5)
                Text(resources.selectText).underline()
            }
            .font(UVVAFont.sans(12))
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// The button that opens the group table, under the list while choosing.
    private var selectionBar: some View {
        VStack(spacing: 8) {
            if let full = model.tableFullText {
                Text(full).font(UVVAFont.sans(11)).opacity(0.75)
            }
            ActionButton(model.selectButtonText, isEnabled: model.canFindBottle, action: viewModel.findBottle)
        }
        .padding(.horizontal, 30)
        .padding(.top, 12)
        .padding(.bottom, 12)
    }

    private var requests: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel(text: resources.requestsText)
                .padding(.bottom, 4)
            ForEach(model.requests) { row in
                FriendRequestRow(resources: resources, row: row,
                                 onAccept: { perform { await viewModel.accept(row.id) } },
                                 onDecline: { perform { await viewModel.decline(row.id) } })
                FriendsRule()
            }
        }
    }

    private var friends: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(model.friends) { row in
                Button {
                    if model.isSelecting { viewModel.toggle(row.id) } else { viewModel.openFriend(row.id) }
                } label: {
                    FriendRow(row: row, isSelected: model.isSelecting ? model.selectedIDs.contains(row.id) : nil,
                              resources: resources)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if row.id != model.friends.last?.id { FriendsRule() }
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
