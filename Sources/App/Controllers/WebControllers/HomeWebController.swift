import Vapor
import Fluent
import Leaf
import SendGrid

struct HomeWebController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        
        let credentialsRoutes = routes.grouped(User.credentialsAuthenticator())
        
        routes.get(use: indexHandler)
        routes.get("register", use: registerHandler)
        routes.post("register", use: registerPostHandler)
        routes.get("login", use: loginHandler)
        credentialsRoutes.post("login", use: loginPostHandler)
        routes.post("logout", use: logoutHandler)
        routes.get("forgottenPassword", use: forgottenPasswordHandler)
        routes.post("forgottenPassword", use: forgottenPasswordPostHandler)
        routes.get("resetPassword", use: resetPasswordHandler)
        routes.post("resetPassword", use: resetPasswordPostHandler)
        
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
        let emailAddress: String
        let twitterUrl: String
        
        static func validations(_ validations: inout Validations) {
            validations.add("name", as: String.self, is: .ascii)
            validations.add("username", as: String.self, is: .alphanumeric && .count(3...))
            validations.add("password", as: String.self, is: .count(8...))
            validations.add("zipCode", as: String.self, is: .zipCode, required: false)
            validations.add("emailAddress", as: String.self, is: .email)
            validations.add("twitterUrl", as: String.self, is: .twitterHandle)
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
            password: password,
            email: data.emailAddress,
            twitterUrl: data.twitterUrl.isEmpty ? nil : data.twitterUrl)
        
        return user.save(on: req.db).map {
            req.auth.login(user)
            
            return req.redirect(to: "/")
        }
    }
    
    struct LoginContext: BaseContext {
        let title = "Log In"
        let userLoggedIn = false
        let loginError: Bool
        let loginWithGoogle = Environment.tilEnv.googleSetup
        let loginWithGithub = Environment.tilEnv.githubSetup
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
    
    struct ForgetPasswordContext: BaseContext {
        let title = "Reset Your Password"
        let userLoggedIn = false
    }
    
    func forgottenPasswordHandler(_ req: Request) -> EventLoopFuture<View> {
        req.view.render("forgottenPassword", ForgetPasswordContext())
    }
    
    struct ForgetPasswordConfirmedContext: BaseContext {
        let title = "Password Reset Email Sent"
        let userLoggedIn = false
    }
    
    func forgottenPasswordPostHandler(_ req: Request) throws -> EventLoopFuture<View> {
        let email = try req.content.get(String.self, at: "email")
        let context = ForgetPasswordConfirmedContext()
        
        return User.query(on: req.db)
            .filter(\.$email == email)
            .first()
            .flatMap { user in
                
                let resetTokenString = Data([UInt8].random(count: 32)).base32EncodedString()
                let resetTokenLink = "\(Environment.tilEnv.LISTEN_FRONT_URL)/resetPassword?token=\(resetTokenString)"
                
                guard let user = user else {
                    // If the user does not exist, act like he does to not reveal anything :x
                    return req.view.render("forgottenPasswordConfirmed", context)
                }
                
                let resetToken: ResetPasswordToken
                do {
                    resetToken = try ResetPasswordToken(token: resetTokenString, userID: user.requireID())
                } catch {
                    return req.eventLoop.future(error: error)
                }
                
                return resetToken.save(on: req.db).flatMap {
                    
                    guard let senderEmail = Environment.tilEnv.SENDGRID_SENDER_EMAIL,
                          Environment.tilEnv.sendgridSetup else {
                        return req.eventLoop.future(error: "Mailing is not set. the link would have been \(resetTokenLink). I know you're not a bad person and won't user it in a bad way !")
                    }
                    
                    let emailContent = """
                        <p>You've requested to reset your password.
                        <a href="\(resetTokenLink)">
                            Click here
                        </a>
                        </p>
                        """
                    let emailAddress = EmailAddress(email: user.email, name: user.name)
                    let fromEmail = EmailAddress(email: senderEmail,
                                                 name: "Vapor TIL")
                    let emailConfig = Personalization(
                        to: [emailAddress],
                        subject: "Reset Your Password")
                    
                    let email = SendGridEmail(
                        personalizations: [emailConfig],
                        from: fromEmail,
                        content: [
                            [
                                "type": "text/html",
                                "value": emailContent
                            ]
                        ]
                    )
                    
                    let emailSend: EventLoopFuture<Void>
                    
                    do {
                        emailSend = try req.application
                            .sendgrid.client.send(email: email, on: req.eventLoop)
                    } catch {
                        return req.eventLoop.future(error: error)
                    }
                    return emailSend.flatMap {
                        return req.view.render("forgottenPasswordConfirmed", context)
                    }
                }
            }
    }
    
    struct ResetPasswordContext: BaseContext {
        let title = "Reset Password"
        let userLoggedIn = false
        let error: Bool
    }
    
    func resetPasswordHandler(_ req: Request) -> EventLoopFuture<View> {
        guard let token = try? req.query.get(String.self, at: "token") else {
            return req.view.render("resetPassword",
                                   ResetPasswordContext(error: true))
        }
        
        return ResetPasswordToken.query(on: req.db)
            .filter(\.$token == token)
            .first()
            .unwrap(or: Abort.redirect(to: "/"))
            .flatMap { token in
                token.$user.get(on: req.db).flatMap { user in
                    do {
                        try req.session.set("ResetPasswordUser", to: user)
                    } catch {
                        return req.eventLoop.future(error: error)
                    }
                    
                    return token.delete(on: req.db)
                }
            }.flatMap {
                req.view.render("resetPassword", ResetPasswordContext(error: false))
            }
    }
    
    struct ResetPasswordData: Content {
        let password: String
        let confirmPassword: String
    }
    
    func resetPasswordPostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        let data = try req.content.decode(ResetPasswordData.self)
        guard data.password == data.confirmPassword else {
            return req.view.render("resetPassword", ResetPasswordContext(error: true))
                .encodeResponse(for: req)
        }
        let resetPasswordUser = try req.session.get("ResetPasswordUser", as: User.self)
        req.session.data["ResetPasswordUser"] = nil
        
        let newPassword = try Bcrypt.hash(data.password)
        
        return try User.query(on: req.db)
            .filter(\.$id == resetPasswordUser.requireID())
            .set(\.$password, to: newPassword)
            .update()
            .transform(to: req.redirect(to: "/login"))
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

extension ValidatorResults {
    struct TwitterHandle: ValidatorResult {
        let isValidTwitterHandle: Bool
        
        var isFailure: Bool {
            !isValidTwitterHandle
        }
        
        var successDescription: String? { "is a valid twitter handle" }
        var failureDescription: String? { "is not a valid twitter handle" }
    }
}

extension Validator where T == String {
    private static var twitterHandleRegex: String {
        "^$|@([A-Za-z0-9_]+)?$"
    }
    
    public static var twitterHandle: Validator<T> {
        Validator { input -> ValidatorResult in
            guard let range = input.range(
                    of: twitterHandleRegex,
                    options: [.regularExpression]),
                  range.lowerBound == input.startIndex
                    && range.upperBound == input.endIndex
            else {
                return ValidatorResults.TwitterHandle(isValidTwitterHandle: false)
            }
            return ValidatorResults.TwitterHandle(isValidTwitterHandle: true)
        }
    }
}
