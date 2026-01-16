import MultipeerConnectivity
import SwiftUI
import Combine

final class MultiplayerManager: NSObject, ObservableObject {
    private let serviceType = "tictacmoji-game"
    private var myPeerId: MCPeerID
    private var serviceAdvertiser: MCNearbyServiceAdvertiser
    private var serviceBrowser: MCNearbyServiceBrowser
    private var session: MCSession
    
    @Published var availablePeers: [MCPeerID] = []
    @Published var connectedPeer: MCPeerID? = nil
    @Published var connectionState: MCSessionState = .notConnected
    @Published var invitationHandler: ((Bool, MCSession?) -> Void)?
    @Published var receivedMove: Int? = nil
    
    // Hosting state
    @Published var isHosting = false
    @Published var isBrowsing = false
    
    override init() {
        let profileName = ProfileManager.shared.currentUser.name
        myPeerId = MCPeerID(displayName: profileName)
        
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        
        super.init()
        
        session.delegate = self
        serviceAdvertiser.delegate = self
        serviceBrowser.delegate = self
    }
    
    func startHosting() {
        isHosting = true
        serviceAdvertiser.startAdvertisingPeer()
    }
    
    func stopHosting() {
        isHosting = false
        serviceAdvertiser.stopAdvertisingPeer()
    }
    
    func startBrowsing() {
        isBrowsing = true
        availablePeers.removeAll()
        serviceBrowser.startBrowsingForPeers()
    }
    
    func stopBrowsing() {
        isBrowsing = false
        serviceBrowser.stopBrowsingForPeers()
    }
    
    func invitePeer(_ peerID: MCPeerID) {
        serviceBrowser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
    }
    
    func sendMove(index: Int) {
        guard let _ = connectedPeer else { return }
        let data = withUnsafeBytes(of: index) { Data($0) }
        do {
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            print("Error sending move: \(error.localizedDescription)")
        }
    }
    
    func handleInvitation(accept: Bool) {
        if accept {
            invitationHandler?(true, session)
        } else {
            invitationHandler?(false, nil)
        }
        invitationHandler = nil
    }
    
    func resetSession() {
        session.disconnect()
        connectedPeer = nil
        connectionState = .notConnected
        availablePeers.removeAll()
    }
}

extension MultiplayerManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Automatically accept for now, or could show UI alert
        // For this task, we can show an alert or just auto-accept if we want seamless.
        // Let's expose it to UI via invitationHandler property to show an alert to the user.
        print("Received invitation from \(peerID.displayName)")
        self.invitationHandler = invitationHandler
    }
}

extension MultiplayerManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        if !availablePeers.contains(peerID) {
            DispatchQueue.main.async {
                self.availablePeers.append(peerID)
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.availablePeers.removeAll(where: { $0 == peerID })
        }
    }
}

extension MultiplayerManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.connectionState = state
            
            switch state {
            case .connected:
                self.connectedPeer = peerID
                self.stopHosting()
                self.stopBrowsing()
            case .notConnected:
                if self.connectedPeer == peerID {
                    self.connectedPeer = nil
                }
            case .connecting:
                break
            @unknown default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let index = data.withUnsafeBytes { $0.load(as: Int.self) }
        DispatchQueue.main.async {
            self.receivedMove = index
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
