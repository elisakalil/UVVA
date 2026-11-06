import Core
import DesignSystem
import SwiftUI

/// Search moves matching terms to the front while keeping the remaining landscape visible.
struct GlossaryView<ViewModel: GlossaryViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    @FocusState private var searching: Bool
    @State private var headerHeight: CGFloat = 44
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var resources: GlossaryResourcesUIModel { viewModel.uiModel.resources }
    private var selected: GlossaryTerm? { viewModel.uiModel.selectedTerm }
    private var query: Binding<String> {
        Binding(get: { viewModel.uiModel.query }, set: { viewModel.updateQuery($0) })
    }

    private func closeDefinition() {
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) { viewModel.closeDefinition() }
    }

    private func handleOutsideTap() {
        let wasSearching = searching
        searching = false
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) {
            viewModel.handleOutsideTap(isSearchFocused: wasSearching)
        }
    }

    var body: some View {
        ZStack {
            background.onTapGesture(perform: handleOutsideTap)
            ZStack(alignment: .top) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 28) {
                            ForEach(Array(viewModel.uiModel.terms.enumerated()), id: \.element.id) { index, row in
                                Button {
                                    searching = false
                                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) { viewModel.selectTerm(row.term) }
                                } label: {
                                    Text(row.term.term)
                                        .font(UVVAFont.whiteGrape(index % 4 == 0 ? 35 : 27))
                                        .multilineTextAlignment(.leading)
                                        .rotationEffect(.degrees(reduceMotion ? 0 : (index % 2 == 0 ? -3 : 2)))
                                        .frame(maxWidth: .infinity, minHeight: 48,
                                               alignment: index % 3 == 0 ? .trailing : .leading)
                                        .padding(.horizontal, index % 2 == 0 ? 16 : 0)
                                        .opacity(row.isMatch ? 1 : 0.18)
                                }
                                .buttonStyle(.plain)
                                .disabled(!row.isMatch)
                                .accessibilityHidden(!row.isMatch)
                                .id(row.id)
                            }
                        }
                        .id("glossary.top")
                        .padding(.horizontal, 28)
                        .padding(.top, headerHeight + 38)
                        .padding(.bottom, 30)
                    }
                    .onTapGesture(perform: handleOutsideTap)
                    .scrollIndicators(.hidden)
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: viewModel.uiModel.query) { _, _ in
                        withAnimation(reduceMotion ? nil : .easeOut) {
                            proxy.scrollTo("glossary.top", anchor: .top)
                        }
                    }
                }
                .blur(radius: selected == nil ? 0 : 3)
                .allowsHitTesting(selected == nil)
                .accessibilityHidden(selected != nil)
                header
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Button(action: viewModel.close) {
                    Text(resources.leaveHint)
                        .font(UVVAFont.sans(10))
                        .tracking(2)
                        .foregroundStyle(UVVAColor.grape)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .allowsHitTesting(selected == nil)
            .accessibilityHidden(selected != nil)

            if selected != nil {
                Color.black.opacity(0.22)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture(perform: handleOutsideTap)
                    .accessibilityLabel(resources.clearSelection)
                    .accessibilityAddTraits(.isButton)
            }
        }
        .overlay(alignment: .bottom) {
            if let selected {
                definition(selected)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .foregroundStyle(UVVAColor.cream)
        .accessibilityAction(.escape, handleOutsideTap)
        .preferredColorScheme(.dark)
    }

    /// Terms scroll behind the transparent header; only the search capsule has a background.
    private var header: some View {
        searchBar.padding(.horizontal, 30)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { headerHeight = $0 }
    }

    private var searchBar: some View {
        HStack(spacing: 9) {
            Image(systemName: resources.searchSymbol)
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(UVVAColor.cream60)
            TextField("", text: query,
                      prompt: Text(resources.searchPrompt).foregroundStyle(UVVAColor.cream60))
                .font(UVVAFont.sans(14))
                .tint(UVVAColor.cream)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($searching)
                .accessibilityLabel(Text(resources.searchPrompt))
            if !viewModel.uiModel.query.isEmpty {
                Button { viewModel.updateQuery("") } label: {
                    Image(systemName: resources.clearSymbol)
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(UVVAColor.cream60)
                        .frame(width: 36, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(resources.clearSearch))
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .frame(minHeight: 44)
        .background { texture.clipShape(Capsule()) }
        .overlay { Capsule().strokeBorder(UVVAColor.cream.opacity(0.25), lineWidth: 0.5) }
    }

    private var texture: some View {
        Color(red: 0.12, green: 0.035, blue: 0.065)
            .overlay { Image(resources.backgroundAsset, bundle: .module).resizable().scaledToFill() }
            .clipped()
    }

    private var background: some View {
        texture.ignoresSafeArea()
    }

    private func definition(_ term: GlossaryTerm) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Button { closeDefinition() } label: {
                Capsule().fill(UVVAColor.cream60).frame(width: 44, height: 4)
                    .frame(maxWidth: .infinity, minHeight: 24)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(resources.closeDefinition)
            Text(term.term).font(UVVAFont.whiteGrape(36))
            if !term.pronunciation.isEmpty {
                Text(term.pronunciation).font(.system(size: 12, design: .serif)).italic()
                    .foregroundStyle(UVVAColor.cream60)
            }
            Text(term.definition).font(UVVAFont.sans(14)).lineSpacing(7)
            if let aka = term.aka, !aka.isEmpty {
                Text(aka.uppercased()).font(UVVAFont.sans(10)).tracking(1.5)
                    .foregroundStyle(UVVAColor.cream60)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 28)
        .padding(.bottom, 24)
        .fixedSize(horizontal: false, vertical: true)
        .background {
            texture
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 32, topTrailingRadius: 32))
                .ignoresSafeArea(edges: .bottom)
        }
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 35).onEnded {
            if $0.translation.height > 45 { closeDefinition() }
        })
    }
}

#Preview {
    GlossaryView(viewModel: GlossaryViewModel(terms: MockData.glossary, initialTerm: MockData.glossary.last, onClose: {}))
}
