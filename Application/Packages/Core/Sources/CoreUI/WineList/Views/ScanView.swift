#if os(iOS)
import DesignSystem
import SwiftUI

/// The scan of the Home's `+` (WINELIST-R01): a bottle's label or a restaurant's wine list, chosen at the top of the
/// camera. The label goes on to the new note and the Cellar; the list to the wines to order tonight. The choice shows
/// only while the camera does, and holds still while a photo is being read.
public struct ScanView: View {
    @ObservedObject var note: NewNoteViewModel
    @ObservedObject var wineList: WineListViewModel
    @State private var mode = Mode.label

    enum Mode: String { case label, list }

    public init(note: NewNoteViewModel, wineList: WineListViewModel) {
        self.note = note
        self.wineList = wineList
    }

    private var resources: WineListResourcesUIModel { wineList.uiModel.resources }

    public var body: some View {
        ZStack {
            NotePalette.cameraGround.ignoresSafeArea()
            switch mode {
            case .label:
                NewNoteView(viewModel: note).transition(.opacity)
            case .list:
                WineListView(viewModel: wineList).transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.35), value: mode)
        .safeAreaInset(edge: .top, spacing: 0) {
            if showsPicker {
                ScanSegmentedPicker(
                    options: [.init(id: Mode.label.rawValue, text: resources.labelModeText, icon: "wineglass"),
                              .init(id: Mode.list.rawValue, text: resources.listModeText, icon: "menucard")],
                    selection: mode.rawValue,
                    onSelect: { mode = Mode(rawValue: $0) ?? .label })
                    .disabled(!canSwitch)
                    .opacity(canSwitch ? 1 : 0.4)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 22)
                    .transition(.opacity)
            }
        }
    }

    /// While the camera shows, on either side.
    private var showsPicker: Bool {
        switch mode {
        case .label: [.checkingCamera, .cameraDenied, .front, .back, .reading, .readFailed, .notWine].contains(note.uiModel.step)
        case .list: [.checkingCamera, .cameraDenied, .capture].contains(wineList.uiModel.step)
        }
    }

    /// Not once the bottle's front is taken, nor while a page is being read.
    private var canSwitch: Bool {
        switch mode {
        case .label: [.checkingCamera, .cameraDenied, .front, .readFailed, .notWine].contains(note.uiModel.step)
        case .list: !wineList.uiModel.isReading
        }
    }
}
#endif
