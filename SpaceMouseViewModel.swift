import Foundation
import AppKit

/// Wraps SPCMObject (ObjC model) and publishes its state for SwiftUI.
/// Implements the five informal-protocol callbacks that SPCMObject calls on its `frontend`.
final class SpaceMouseViewModel: NSObject, ObservableObject {

    // MARK: - Published state (State tab)
    @Published var dominantOn      = false
    @Published var rotationOn      = false
    @Published var translationOn   = false
    @Published var rotQuality:  Int = 0
    @Published var transQuality: Int = 0
    @Published var nullRadius:   Int = 0

    // MARK: - Published state (Settings tab)
    @Published var portNames:         [String] = []
    @Published var selectedPortIndex: Int      = 0
    @Published var rotScale:          Float    = 1.0
    @Published var transScale:        Float    = 1.0
    @Published var isConnected = false

    // MARK: - Private model objects (non-ARC ObjC; ARC manages the references here)
    private let mouse = SPCMObject()!
    private let ports = PortnamesObject()!

    // MARK: - Init
    override init() {
        super.init()

        mouse.setFrontend(self)

        ports.buildPortnamesArray()
        portNames = ports.portNames() as? [String] ?? []

        rotScale  = mouse.rotScale()
        transScale = mouse.transScale()

        if mouse.hasPrefsFile() {
            selectedPortIndex = Int(mouse.selectedPortItem())
            let path = ports.getDevicePath(fromMenuitem: Int32(selectedPortIndex))
            mouse.setDevPathString(path)
            _ = mouse.connectToDevice()
            isConnected = mouse.isConnected()
            if !isConnected {
                // Settings tab will be shown (handled in ContentView via isConnected)
            }
        }

        // Write prefs and disconnect cleanly on quit
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            _ = self.mouse.prefsToDisk()
            _ = self.mouse.disconnectFromDevice()
        }
    }

    // MARK: - Actions

    func applySettings() {
        let currentPort = Int(mouse.selectedPortItem())
        if selectedPortIndex != currentPort {
            _ = mouse.disconnectFromDevice()
            mouse.setSelectedPortItem(selectedPortIndex)
            let path = ports.getDevicePath(fromMenuitem: Int32(selectedPortIndex))
            mouse.setDevPathString(path)
            _ = mouse.connectToDevice()
            isConnected = mouse.isConnected()
        }
        _ = mouse.setRotScale(rotScale)
        _ = mouse.setTransScale(transScale)
    }

    func refreshPorts() {
        ports.buildPortnamesArray()
        portNames = ports.portNames() as? [String] ?? []
    }

    // MARK: - SPCMObject frontend callbacks (called on whatever thread delivers serial data)

    @objc func UpdateModes(_ sender: Any) {
        guard let m = sender as? SPCMObject else { return }
        let dom   = m.domModeOn()
        let rot   = m.rotOn()
        let trans = m.transOn()
        DispatchQueue.main.async { [weak self] in
            self?.dominantOn    = dom
            self?.rotationOn    = rot
            self?.translationOn = trans
        }
    }

    @objc func UpdateSensitivities(_ sender: Any) {
        guard let m = sender as? SPCMObject else { return }
        let rq = Int(m.rotQuality())
        let tq = Int(m.transQuality())
        DispatchQueue.main.async { [weak self] in
            self?.rotQuality  = rq
            self?.transQuality = tq
        }
    }

    @objc func UpdateNullRadius(_ sender: Any) {
        guard let m = sender as? SPCMObject else { return }
        let nr = Int(m.nullRad())
        DispatchQueue.main.async { [weak self] in
            self?.nullRadius = nr
        }
    }

    @objc func takeRotScaleFrom(_ sender: Any) {
        guard let m = sender as? SPCMObject else { return }
        let s = m.rotScale()
        DispatchQueue.main.async { [weak self] in
            self?.rotScale = s
        }
    }

    @objc func takeTransScaleFrom(_ sender: Any) {
        guard let m = sender as? SPCMObject else { return }
        let s = m.transScale()
        DispatchQueue.main.async { [weak self] in
            self?.transScale = s
        }
    }
}
