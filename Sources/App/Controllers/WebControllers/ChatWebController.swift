import Vapor
import Leaf

struct ChatWebController: RouteCollection {
    
    let chatSockets = ClassBox<[WeakBox<WebSocket>]>([])
    var activeChatSockets: [WebSocket] {
        self.chatSockets.unbox.compactMap(\.unbox).filter(\.isActive)
    }
    
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
        
        let username = req.auth.get(User.self)?.name ?? "<unknown>"
        self.chatSockets.unbox.append(WeakBox(webSocket))
        webSocket.onText { ws, text in
            self.activeChatSockets.forEach {
                $0.send("\(username): \(text)")
            }
        }

    }

    func listSocketsHandler(_ req: Request) -> [String] {
        self.chatSockets.unbox.map { wsBox in
            if let ws = wsBox.unbox {
                return ws.isClosed ? "<closed>" : "\(MemoryAddress(of: ws))"
            } else {
                return "<nil>"
            }
        }
    }

}
