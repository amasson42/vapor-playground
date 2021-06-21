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
            credentialsAuth: authSessionRoutes.grouped(User.credentialsAuthenticator()),
            protected: authSessionRoutes.grouped(User.redirectMiddleware(path: "/login")))
    }
    
}

struct HomeWebController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let authRoutes = routes.makeAuthRoutes(controllerName: "")
        
        authRoutes.authSession.get(use: indexHandler)
        authRoutes.authSession.get("register", use: registerHandler)
        authRoutes.authSession.post("register", use: registerPostHandler)
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
        
        let context = IndexContext(
            userLoggedIn: req.auth.has(User.self),
            showCookieMessage: req.cookies["cookies-accepted"] == nil
        )
        
        return req.view.render("index", context)
    }
    
    // MARK: Register
    
    struct RegisterContext: BaseContext {
        let title = "Register"
        let userLoggedIn = false
        let registerError: String?
    }
    
    func registerHandler(_ req: Request) -> EventLoopFuture<View> {
        
        let context = RegisterContext(
            registerError: req.query[String.self, at: "registerError"]
        )
        
        return req.view.render("register", context)
    }
    
    struct RegisterData: Validatable, Content {
        let name: String
        let username: String
        let password: String
        let confirmPassword: String
        
        static func validations(_ validations: inout Validations) {
            validations.add("name", as: String.self, is: .ascii)
            validations.add("username", as: String.self, is: .alphanumeric && .count(3...))
            validations.add("password", as: String.self, is: .count(8...))
        }
        
    }
    
    func registerPostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        
        do {
            try RegisterData.validate(content: req)
        } catch let error as ValidationsError {
            let message = error.description
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Unknown error"
            let redirect = req.redirect(to: "/register?registerError=\(message)")
            return req.eventLoop.future(redirect)
        } catch {
            return req.eventLoop.future(req.redirect(to: "/register"))
        }
        
        let data = try req.content.decode(RegisterData.self)
        
        let password = try Bcrypt.hash(data.password)
        
        let user = User(
            name: data.name,
            username: data.username,
            password: password)
        
        return user.save(on: req.db).map {
            req.auth.login(user)
            
            return req.redirect(to: "/")
        }
    }
    
    struct LoginContext: BaseContext {
        let title = "Log In"
        let userLoggedIn = false
        let loginError: Bool
    }
    
    func loginHandler(_ req: Request) -> EventLoopFuture<View> {
        let context = LoginContext(
            loginError: req.query[Bool.self, at: "error"] == true)
        
        return req.view.render("login", context)
    }
    
    func loginPostHandler(_ req: Request) -> EventLoopFuture<Response> {
        if req.auth.has(User.self) {
            return req.eventLoop.future(req.redirect(to: "/"))
        } else {
            let context = LoginContext(
                loginError: true)
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
    var useSelect2: Bool { false }
}
