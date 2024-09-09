import Foundation

actor MagicLinkActor: MagicLinkProtocol {
    private let baseURL: URL
    private let session: URLSession
    private let tokenManager: TokenManager
    
    init(baseURL: URL, session: URLSession = .shared, tokenManager: TokenManager) {
        self.baseURL = baseURL
        self.session = session
        self.tokenManager = tokenManager
    }
    
    nonisolated func generateMagicLink(for email: String, expirationTime: TimeInterval) -> URL {
        let token = tokenManager.encodeToken(email: email, expirationTime: Date().addingTimeInterval(expirationTime), additionalData: nil)
        return baseURL.appendingPathComponent("auth").appendingPathComponent(token)
    }
    
    func sendMagicLink(to email: String, link: URL) async throws -> Bool {
        let request = URLRequest(url: baseURL.appendingPathComponent("send-magic-link"))
        let payload = ["email": email, "link": link.absoluteString]
        var responseContent: (Data, URLResponse)
        
        #if os(macOS)
        if #available(macOS 12.0, *) {
            responseContent = try await session.upload(for: request, from: JSONEncoder().encode(payload))
        } else {
            responseContent = try await withCheckedThrowingContinuation { continuation in
                session.uploadTask(with: request, from: try? JSONEncoder().encode(payload)) { data, response, error in 
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let data = data, let response = response else {
                        continuation.resume(throwing: MagicLinkError.sendFailed)
                        return
                    }
                    
                    continuation.resume(returning: (data, response))
                }.resume()
            }
        }
        #else
        responseContent = try await session.data(for: request, from: try JSONEncoder().encode(payload))
        #endif
        
        guard let httpResponse = responseContent.1 as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw MagicLinkError.sendFailed
        }
        
        let result = try JSONDecoder().decode(SendMagicLinkResponse.self, from: responseContent.0)
        return result.success
    }
    
    func verifyMagicLinkToken(_ token: String) async throws -> Bool {
        let request = URLRequest(url: baseURL.appendingPathComponent("verify-token"))
        let payload = ["token": token]
        let (data, response) = try await session.upload(for: request, from: try JSONEncoder().encode(payload))
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw MagicLinkError.verificationFailed
        }
        
        let result = try JSONDecoder().decode(VerifyTokenResponse.self, from: data)
        return result.valid
    }
    
    func authenticateUser(withToken token: String) async throws -> AuthenticatedUser? {
        guard try await verifyMagicLinkToken(token) else {
            return nil
        }
        
        let request = URLRequest(url: baseURL.appendingPathComponent("authenticate"))
        let payload = ["token": token]
        let (data, response) = try await session.upload(for: request, from: try JSONEncoder().encode(payload))
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw MagicLinkError.authenticationFailed
        }
        
        return try? JSONDecoder().decode(AuthenticatedUser.self, from: data)
    }
    
    nonisolated func encodeToken(email: String, expirationTime: Date, additionalData: [String : Any]?) -> String {
        tokenManager.encodeToken(email: email, expirationTime: expirationTime, additionalData: additionalData)
    }
    
    nonisolated func decodeToken(_ token: String) throws -> MagicLinkToken {
        try tokenManager.decodeToken(token)
    }
}

// Helper structures and enums
struct SendMagicLinkResponse: Codable {
    let success: Bool
}

struct VerifyTokenResponse: Codable {
    let valid: Bool
}

enum MagicLinkError: Error {
    case sendFailed
    case verificationFailed
    case authenticationFailed
}

// TokenManager to handle token encoding and decoding
class TokenManager {
    private let secretKey: String
    
    init(secretKey: String) {
        self.secretKey = secretKey
    }
    
    func encodeToken(email: String, expirationTime: Date, additionalData: [String : Any]?) -> String {
        // Implement token encoding logic here
        // This is a placeholder implementation
        let payload = [
            "email": email,
            "exp": Int(expirationTime.timeIntervalSince1970),
            "additionalData": additionalData ?? [:]
        ] as [String : Any]
        return try! JSONSerialization.data(withJSONObject: payload).base64EncodedString()
    }
    
    func decodeToken(_ token: String) throws -> MagicLinkToken {
        // Implement token decoding logic here
        // This is a placeholder implementation
        guard let data = Data(base64Encoded: token),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let email = json["email"] as? String,
              let exp = json["exp"] as? Int,
              let additionalData = json["additionalData"] as? [String: Any] else {
            throw MagicLinkError.verificationFailed
        }
        
        return MagicLinkToken(
            email: email,
            expirationTime: Date(timeIntervalSince1970: TimeInterval(exp)),
            additionalData: additionalData
        )
    }
}
