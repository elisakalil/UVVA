import DesignSystem
import SwiftUI

/// A friend (FRIENDS.md §5): who they are, then Palate, Compatibility and Table.
struct FriendProfileView<ViewModel: FriendProfileViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel

    private var model: FriendProfileUIModel { viewModel.uiModel }
    private var resources: FriendProfileResourcesUIModel { model.resources }

    var body: some View {
        ZStack(alignment: .top) {
            PageBackground(blur: 2, veiled: true)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    FriendProfileTabBar(resources: resources, selected: model.tab, onSelect: viewModel.selectTab)
                        .padding(.top, 28)
                    content.padding(.top, 28)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .foregroundStyle(UVVAColor.creamFill)
        .task { await viewModel.load() }
        .confirmationDialog(model.removeTitle,
                            isPresented: Binding(get: { model.isConfirmingRemoval }, set: { if !$0 { viewModel.cancelRemoval() } }),
                            titleVisibility: .visible) {
            Button(resources.removeText, role: .destructive) { Task { await viewModel.confirmRemoval() } }
            Button(resources.cancelText, role: .cancel) { viewModel.cancelRemoval() }
        } message: {
            Text(model.removeBody)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: viewModel.close) {
                    Image(systemName: resources.closeIcon)
                        .font(.system(size: 15, weight: .light))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(resources.closeText)
                .padding(.leading, -12)
                Spacer()
                Menu {
                    Button(resources.removeText, role: .destructive, action: viewModel.askToRemove)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .light))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .padding(.trailing, -12)
            }
            .padding(.top, 8)
            HStack(spacing: 18) {
                Avatar(photo: nil, size: 64)
                VStack(alignment: .leading, spacing: 8) {
                    Text(model.name).font(UVVAFont.sans(28, .ultraLight)).lineLimit(1).minimumScaleFactor(0.7)
                        .accessibilityAddTraits(.isHeader)
                    Text(model.signature).font(UVVAFont.sans(9.5)).tracking(1.6).opacity(0.75)
                }
                Spacer(minLength: 0)
                Text(model.compatibilityText).font(UVVAFont.sans(28, .ultraLight)).monospacedDigit()
            }
            .padding(.top, 18)
        }
    }

    @ViewBuilder private var content: some View {
        switch model.tab {
        case .palate: palate
        case .compatibility: compatibility
        case .table: table
        }
    }

    /// FRI-R11
    private var palate: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: model.palateTitle)
            FriendChart(values: model.friendChart, strong: model.strongAxes).padding(.top, 10)
            Text(model.caption).font(UVVAFont.sans(15, .light)).lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
            SectionLabel(text: resources.readingsText).padding(.top, 26)
            VStack(spacing: 0) {
                ForEach(model.readings) { row in
                    PalateReadingLine(name: row.name, level: row.level, word: row.word, isStrong: row.isStrong)
                }
            }
            .padding(.top, 6)
        }
    }

    /// FRI-R12
    private var compatibility: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(model.matchTitle).font(UVVAFont.sans(22, .ultraLight)).lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            FriendChart(values: model.friendChart, comparison: model.userChart).padding(.top, 10)
            Text(resources.youAnd(model.name).uppercased()).font(UVVAFont.sans(9)).tracking(1.8).opacity(0.62)
                .frame(maxWidth: .infinity)
            Text(model.overlapPhrase).font(UVVAFont.sans(15, .light)).lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 22)
            SectionLabel(text: resources.table.openTogetherText).padding(.top, 20)
            TableBottlesList(resources: resources.table, bottles: model.bottles, style: .axis)
        }
    }

    /// FRI-R13, R15
    private var table: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(model.dinnerTitle).font(UVVAFont.sans(22, .ultraLight)).lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            TableBottlesList(resources: resources.table, bottles: model.bottles, style: .course)
                .padding(.top, 10)
            Text(resources.menuFooterText.uppercased()).font(UVVAFont.sans(8.5)).tracking(1.8).opacity(0.55)
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
        }
    }
}

#if DEBUG
#Preview {
    FriendProfileView(viewModel: MockFriendProfileViewModel())
}
#endif
