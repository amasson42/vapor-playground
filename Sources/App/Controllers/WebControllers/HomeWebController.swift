import Vapor
import Leaf

struct AuthRoutes {
    let group: RoutesBuilder
    let authSession: RoutesBuilder
    let credentialsAuth: RoutesBuilder
    let protected: RoutesBuilder
}

extension RoutesBuilder {
    
    func makeAuthRoutes(controllerName: String) -> AuthRoutes {
        let controllerGroup = self.grouped(.init(stringLiteral: controllerName))
        let authSessionRoutes = controllerGroup.grouped(User.sessionAuthenticator())
        return AuthRoutes(
            group: controllerGroup,
            authSession: authSessionRoutes,
            credentialsAuth: controllerGroup.grouped(User.credentialsAuthenticator()),
            protected: authSessionRoutes.grouped(User.redirectMiddleware(path: "/login")))
    }
    
}

struct HomeWebController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let authRoutes = routes.makeAuthRoutes(controllerName: "")
        
        authRoutes.authSession.get(use: indexHandler)
        authRoutes.authSession.get("login", use: loginHandler)
        authRoutes.credentialsAuth.post("login", use: loginPostHandler)
        authRoutes.authSession.post("logout", use: logoutHandler)
        
    }
    
    struct IndexContext: BaseContext {
        let title = "Home Page"
        let userLoggedIn: Bool
        let showCookieMessage: Bool
    }
    
    func indexHandler(_ req: Request) -> EventLoopFuture<View> {
        
        let userLoggedIn = req.auth.has(User.self)
        let context = IndexContext(
            userLoggedIn: userLoggedIn,
            showCookieMessage: req.cookies["cookies-accepted"] == nil
        )
        
        return req.view.render("index", context)
    }
    
    struct LoginContext: BaseContext {
        let title = "Log In"
        let userLoggedIn = false
        let loginError: Bool
        
        init(loginError: Bool = false) {
            self.loginError = loginError
        }
    }
    
    func loginHandler(_ req: Request) -> EventLoopFuture<View> {
        let context: LoginContext
        if let error = req.query[Bool.self, at: "error"], error {
            context = LoginContext(loginError: true)
        } else {
            context = LoginContext()
        }
        
        return req.view.render("login", context)
    }
    
    func loginPostHandler(_ req: Request) -> EventLoopFuture<Response> {
        if req.auth.has(User.self) {
            return req.eventLoop.future(req.redirect(to: "/"))
        } else {
            let context = LoginContext(loginError: true)
            return req.view.render("login", context)
                .encodeResponse(for: req)
        }
    }
    
    func logoutHandler(_ req: Request) -> Response {
        req.auth.logout(User.self)
        return req.redirect(to: "/")
    }
    
}

protocol BaseContext: Encodable {
    var title: String { get }
    var userLoggedIn: Bool { get }
    var useSelect2: Bool { get }
}

extension BaseContext {
    var title: String { "Title" }
    var useSelect2: Bool { false }
}
