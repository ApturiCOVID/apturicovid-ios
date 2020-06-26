import Foundation
import TrustKit

class TrustCheck {
    static func isServerCertValid(_ challenge: URLAuthenticationChallenge, session: URLSession) -> Bool {
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            return false
        }
        
        let pinningValidator = TrustKit.sharedInstance().pinningValidator
        let trustDecision = pinningValidator.evaluateTrust(serverTrust, forHostname: challenge.protectionSpace.host)
        
        return trustDecision == .shouldAllowConnection
    }
}

class NSURLSessionPinningDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        if TrustCheck.isServerCertValid(challenge, session: session) {
            completionHandler(URLSession.AuthChallengeDisposition.useCredential, nil)
        } else {
            completionHandler(URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge, nil)
        }
    }
}

