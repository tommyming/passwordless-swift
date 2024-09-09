import Foundation

public protocol MagicLinkProtocol {
    /// Generate a magic link for the given email
    /// - Parameters:
    ///   - email: The user's email address
    ///   - expirationTime: The duration for which the link is valid
    /// - Returns: A generated magic link URL
    func generateMagicLink(for email: String, expirationTime: TimeInterval) -> URL
    
    /// Send a magic link to the user's email
    /// - Parameters:
    ///   - email: The user's email address
    ///   - link: The generated magic link URL
    /// - Returns: A boolean indicating whether the email was sent successfully
    func sendMagicLink(to email: String, link: URL) async throws -> Bool
    
    /// Verify the magic link token
    /// - Parameter token: The token extracted from the magic link URL
    /// - Returns: A boolean indicating whether the token is valid and not expired
    func verifyMagicLinkToken(_ token: String) async throws -> Bool
    
    /// Authenticate the user using the verified token
    /// - Parameter token: The verified magic link token
    /// - Returns: An authenticated user object or nil if authentication fails
    func authenticateUser(withToken token: String) async throws -> AuthenticatedUser?
    
    /// Encode the necessary information into a magic link token
    /// - Parameters:
    ///   - email: The user's email address
    ///   - expirationTime: The expiration time of the token
    ///   - additionalData: Any additional data to be included in the token
    /// - Returns: An encoded token string
    func encodeToken(email: String, expirationTime: Date, additionalData: [String: Any]?) -> String
    
    /// Decode a magic link token
    /// - Parameter token: The encoded token string
    /// - Returns: A decoded MagicLinkToken object
    func decodeToken(_ token: String) throws -> MagicLinkToken
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