import Vapor
import Leaf

struct WebsiteController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        routes.get(use: handleIndex)
    }
    
    func handleIndex(_ req: Request) throws -> EventLoopFuture<View> {
        try shell("pwd; ls -al") {
            r in
            print(r.stdout)
        }
        return req.view.render("index")
    }
    
}
