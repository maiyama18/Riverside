@testable import App
import XCTVapor

final class AppTests: XCTestCase {
    var app: Application!
    
    override func setUp() async throws {
        self.app = try await Application.make(.testing)
        try await configure(app)
    }
    
    override func tearDown() async throws { 
        try await self.app.asyncShutdown()
        self.app = nil
    }
    
    func testHelloWorld() async throws {
        try await self.app.test(.GET, "", afterResponse: { res async in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqualJSON(
                res.body.string,
                [
                    "message": "Hello, world!"
                ]
            )
        })
    }
}
