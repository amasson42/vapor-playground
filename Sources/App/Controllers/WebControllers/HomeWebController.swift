import Vapor
import Fluent
import Leaf

struct HomeWebController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        
        let credentialsRoutes = routes.grouped(User.credentialsAuthenticator())
        
        routes.get(use: indexHandler)
        routes.get("register", use: registerHandler)
        routes.post("register", use: registerPostHandler)
        routes.get("login", use: loginHandler)
        credentialsRoutes.post("login", use: loginPostHandler)
        routes.post("logout", use: logoutHandler)
        
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
            validations.add("zipCode", as: String.self, is: .zipCode, required: false)
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

extension ValidatorResults {
    struct ZipCode: ValidatorResult {
        let isValidZipCode: Bool
        
        var isFailure: Bool {
            !isValidZipCode
        }
        
        var successDescription: String? { "is a valid zip code" }
        var failureDescription: String? { "is not a valid zip code" }
    }
}

extension Validator where T == String {
    private static var zipCodeRegex: String {
        "^\\d{5}(?:[-\\s]\\d{4})?$"
    }
    
    public static var zipCode: Validator<T> {
        Validator { input -> ValidatorResult in
            guard let range = input.range(
                    of: zipCodeRegex,
                    options: [.regularExpression]),
                range.lowerBound == input.startIndex
                    && range.upperBound == input.endIndex
            else {
                return ValidatorResults.ZipCode(isValidZipCode: false)
            }
            return ValidatorResults.ZipCode(isValidZipCode: true)
        }
    }
}
