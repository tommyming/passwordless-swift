import Foundation
import FoundationNetworking
import JWTKit

// MARK: As the latest implementation, URLSession is under FoundationNetworking module.

struct URLSessionMagicLink: MagicLinkProtocol {
    let session: URLSession

    func generateMagicLink(for email: String, expirationTime: TimeInterval) -> URL {

    }

    func sendMagicLink(to email: String, link: URL) async throws -> Bool {
        
    }

    func verifyMagicLinkToken(_ token: String) async throws -> Bool {
        
    }

    func authenticateUser(withToken token: String) async throws -> AuthenticatedUser? {
        
    }

    func encodeToken(email: String, expirationTime: Date, additionalData: [String : Any]?) -> String {
        
    }

    func decodeToken(_ token: String) throws -> MagicLinkToken {
        
    }
}

public struct MagicLinkToken {
    public let email: String
    public let expirationTime: Date
    public let additionalData: [String: Any]?
}

public struct AuthenticatedUser: Codable {
    public let id: String
    public let email: String
}
