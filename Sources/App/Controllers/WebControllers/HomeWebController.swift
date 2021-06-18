import Vapor
import Leaf

struct HomeWebController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        routes.get(use: indexHandler)
    }
    
    func indexHandler(_ req: Request) -> EventLoopFuture<View> {
        req.view.render("index", [
            "title": "Home Page"
        ])
    }
    
}

protocol BaseContext: Encodable {
    var title: String { get }
}

extension BaseContext {
    var title: String {
        "Title"
    }
}
