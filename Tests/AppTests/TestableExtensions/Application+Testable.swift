import XCTVapor
import App

extension Application {
    static func testable() throws -> Application {
        let app = Application(.testing)
        
        do {
            try configure(app)
            
            try app.autoRevert().wait()
            try app.autoMigrate().wait()
        } catch {
            app.shutdown()
            throw error
        }
        
        return app
    }
}
