import Foundation
import Vapor
import JWT

struct VaporMagicLinkService: MagicLinkProtocol {
    let app: Application
    let jwtSigners: JWTSigners
    let baseURL: String
    
    init(app: Application, jwtSecret: String, baseURL: String) {
        self.app = app
        self.jwtSigners = JWTSigners()
        self.jwtSigners.use(.hs256(key: jwtSecret))
        self.baseURL = baseURL
    }
    
    func generateMagicLink(for email: String, expirationTime: TimeInterval) -> URL {
        let expirationDate = Date().addingTimeInterval(expirationTime)
        let token = encodeToken(email: email, expirationTime: expirationDate, additionalData: nil)
        return URL(string: "\(baseURL)/auth/verify?token=\(token)")!
    }
    
    func sendMagicLink(to email: String, link: URL) async throws -> Bool {
        // Implement email sending logic here
        // For this example, we'll just print the link
        print("Magic link sent to \(email): \(link)")
        return true
    }
    
    func verifyMagicLinkToken(_ token: String) async throws -> Bool {
        do {
            let decodedToken = try decodeToken(token)
            return decodedToken.expirationTime > Date()
        } catch {
            return false
        }
    }
    
    func authenticateUser(withToken token: String) async throws -> AuthenticatedUser? {
        let decodedToken = try decodeToken(token)
        if decodedToken.expirationTime > Date() {
            // In a real implementation, you'd fetch the user from a database
            return AuthenticatedUser(id: UUID().uuidString, email: decodedToken.email)
        }
        return nil
    }
    
    func encodeToken(email: String, expirationTime: Date, additionalData: [String : Any]?) -> String {
        let payload = MagicLinkJWTPayload(
            subject: "Magic Link",
            expiration: .init(value: expirationTime),
            email: email,
            additionalData: additionalData
        )
        
        return try! jwtSigners.sign(payload)
    }
    
    func decodeToken(_ token: String) throws -> MagicLinkToken {
        let payload = try jwtSigners.verify(token, as: MagicLinkJWTPayload.self)
        return MagicLinkToken(
            email: payload.email,
            expirationTime: payload.expiration.value,
            additionalData: payload.additionalData
        )
    }
}

struct MagicLinkJWTPayload: JWTPayload {
    var subject: SubjectClaim
    var expiration: ExpirationClaim
    var email: String
    var additionalData: [String: Any]?
    
    func verify(using signer: JWTSigner) throws {
        try expiration.verifyNotExpired()
    }
}