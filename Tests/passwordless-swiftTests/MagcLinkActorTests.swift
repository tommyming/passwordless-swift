import XCTest
@testable import Passwordless


class MagicLinkActorTests: XCTestCase {
    var sut: MagicLinkActor!
    var mockURLSession: MockURLSession!
    var mockTokenManager: MockTokenManager!
    
    override func setUp() {
        super.setUp()
        let baseURL = URL(string: "https://example.com")!
        mockURLSession = MockURLSession()
        mockTokenManager = MockTokenManager(secretKey: "12345678")
        sut = MagicLinkActor(baseURL: baseURL, session: mockURLSession, tokenManager: mockTokenManager)
    }
    
    override func tearDown() {
        sut = nil
        mockURLSession = nil
        mockTokenManager = nil
        super.tearDown()
    }
    
    func testGenerateMagicLink() {
        // Given
        let email = "test@example.com"
        let expirationTime: TimeInterval = 3600
        let expectedToken = "mockToken"
        mockTokenManager.mockEncodedToken = expectedToken
        
        // When
        let result = sut.generateMagicLink(for: email, expirationTime: expirationTime)
        
        // Then
        XCTAssertEqual(result.absoluteString, "https://example.com/auth/mockToken")
    }
    
    func testSendMagicLink() async throws {
        // Given
        let email = "test@example.com"
        let link = URL(string: "https://example.com/auth/mockToken")!
        mockURLSession.mockData = try JSONEncoder().encode(SendMagicLinkResponse(success: true))
        mockURLSession.mockResponse = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        // When
        let result = try await sut.sendMagicLink(to: email, link: link)
        
        // Then
        XCTAssertTrue(result)
    }
    
    func testVerifyMagicLinkToken() async throws {
        // Given
        let token = "validToken"
        mockURLSession.mockData = try JSONEncoder().encode(VerifyTokenResponse(valid: true))
        mockURLSession.mockResponse = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        // When
        let result = try await sut.verifyMagicLinkToken(token)
        
        // Then
        XCTAssertTrue(result)
    }
    
    func testAuthenticateUser() async throws {
        // Given
        let token = "validToken"
        let mockUser = AuthenticatedUser(id: "123", email: "test@example.com")
        mockURLSession.mockData = try JSONEncoder().encode(mockUser)
        mockURLSession.mockResponse = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        // When
        let result = try await sut.authenticateUser(withToken: token)
        
        // Then
        XCTAssertEqual(result?.id, mockUser.id)
        XCTAssertEqual(result?.email, mockUser.email)
    }
    
    func testEncodeToken() {
        // Given
        let email = "test@example.com"
        let expirationTime = Date()
        let additionalData: [String: Any] = ["key": "value"]
        let expectedToken = "encodedToken"
        mockTokenManager.mockEncodedToken = expectedToken
        
        // When
        let result = sut.encodeToken(email: email, expirationTime: expirationTime, additionalData: additionalData)
        
        // Then
        XCTAssertEqual(result, expectedToken)
    }
    
    func testDecodeToken() throws {
        // Given
        let token = "validToken"
        let expectedDecodedToken = MagicLinkToken(email: "test@example.com", expirationTime: Date(), additionalData: [:])
        mockTokenManager.mockDecodedToken = expectedDecodedToken
        
        // When
        let result = try sut.decodeToken(token)
        
        // Then
        XCTAssertEqual(result.email, expectedDecodedToken.email)
        XCTAssertEqual(result.expirationTime, expectedDecodedToken.expirationTime)
        XCTAssertEqual(result.additionalData as? [String: String], expectedDecodedToken.additionalData as? [String: String])
    }
}

// MARK: - Mock Classes

// TODO: Updte mock implementation
class MockURLSession: URLSession {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?

    func data(for request: URLRequest, delegate: URLSessionTaskDelegate? = nil) async throws -> (Data, URLResponse) {
        if let mockError = mockError {
            throw mockError
        }
        return (mockData ?? Data(), mockResponse ?? URLResponse())
    }
    
    func upload(for request: URLRequest, from bodyData: Data, delegate: URLSessionTaskDelegate? = nil) async throws -> (Data, URLResponse) {
        if let mockError = mockError {
            throw mockError
        }
        return (mockData ?? Data(), mockResponse ?? URLResponse())
    }
}

class MockTokenManager: TokenManager {
    var mockEncodedToken: String?
    var mockDecodedToken: MagicLinkToken?
    
    override func encodeToken(email: String, expirationTime: Date, additionalData: [String : Any]?) -> String {
        return mockEncodedToken ?? ""
    }
    
    override func decodeToken(_ token: String) throws -> MagicLinkToken {
        if let mockDecodedToken = mockDecodedToken {
            return mockDecodedToken
        }
        throw MagicLinkError.verificationFailed
    }
}

// MARK: - Helper Structures

struct AuthenticatedUser: Codable {
    let id: String
    let email: String
}

struct MagicLinkToken {
    let email: String
    let expirationTime: Date
    let additionalData: [String: Any]
}