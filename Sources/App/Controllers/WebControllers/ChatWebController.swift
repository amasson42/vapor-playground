import Vapor
import Leaf

fileprivate var chatSockets: [WeakBox<WebSocket>] = []

struct ChatWebController: RouteCollection {


    func boot(routes: RoutesBuilder) {
        
        let group = routes.grouped("chat")
        let protected = group.grouped(User.redirectMiddleware(path: "/login"))
        
        protected.get(use: indexHandler)
        group.webSocket("socket", onUpgrade: webSocketHandler)
        group.get("list", use: listSocketsHandler)
    }

    struct ChatContext: BaseContext {
        let title = "Chat"
        let userLoggedIn = true
        let username: String
    }

    func indexHandler(_ req: Request) throws -> EventLoopFuture<View> {
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }
        let context = ChatContext(username: user.name)
        return req.view.render("Chat/index", context)
    }

    func webSocketHandler(_ req: Request, webSocket: WebSocket) {
        chatSockets.append(WeakBox(webSocket))
        webSocket.onText { ws, text in
            req.logger.info("[\(MemoryAddress(of: webSocket))][\(MemoryAddress(of: ws))]: \(text)")
        }

    }

    func listSocketsHandler(_ req: Request) -> [String] {
        chatSockets.map { wsBox in
            if let ws = wsBox.unbox {
                return "\(MemoryAddress(of: ws))\(ws.isClosed ? "-X" : "")"
            } else {
                return "<nil>"
            }
        }
    }

}
