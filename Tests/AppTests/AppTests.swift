@testable import App
import XCTVapor

final class AppTests: XCTestCase {
    
    var app: Application!
    
    override func setUpWithError() throws {
        app = try Application.testable()
    }
    
    override func tearDownWithError() throws {
        app?.shutdown()
    }
    
    func testGetHome() throws {
        try app.test(
            .GET, "/",
            afterResponse: { response in
                XCTAssertEqual(response.status, .ok)
            }
        )
    }
    
}
