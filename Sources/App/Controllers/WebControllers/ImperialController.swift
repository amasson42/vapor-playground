import Vapor
import Fluent
import ImperialGoogle
import ImperialGitHub

struct ImperialController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        
        if let googleCallback = Environment.tilEnv.GOOGLE_CALLBACK_URL,
           Environment.tilEnv.GOOGLE_CLIENT_ID != nil,
           Environment.tilEnv.GOOGLE_CLIENT_SECRET != nil {
            do {
                try routes.oAuth(
                    from: Google.self,
                    authenticate: "login-google",
                    callback: googleCallback,
                    scope: ["profile", "email"],
                    completion: processGoogleLogin)
            } catch {
                print(error)
            }
        }
        
        if let githubCallback = Environment.tilEnv.GITHUB_CALLBACK_URL,
           Environment.tilEnv.GITHUB_CLIENT_ID != nil,
           Environment.tilEnv.GITHUB_CLIENT_SECRET != nil {
            do {
                try routes.oAuth(
                    from: GitHub.self,
                    authenticate: "login-github",
                    callback: githubCallback,
                    scope: ["user:email"],
                    completion: processGitHubLogin)
            } catch {
                print(error)
            }
        }
        
    }
    
    func processGoogleLogin(request: Request, token: String) throws -> EventLoopFuture<ResponseEncodable> {
        
        return try Google.getUser(on: request)
            .flatMap { userInfo in
                User.query(on: request.db)
                    .filter(\.$username == userInfo.email)
                    .first()
                    .flatMap { foundUser in
                        if let existingUser = foundUser {
                            request.session.authenticate(existingUser)
                            return request.eventLoop
                                .future(request.redirect(to: "/"))
                        } else {
                            let user = User(name: userInfo.name,
                                            username: userInfo.email,
                                            password: UUID().uuidString,
                                            email: userInfo.email)
                            return user.save(on: request.db)
                                .map {
                                    request.session.authenticate(user)
                                    return request.redirect(to: "/")
                                }
                        }
                    }
            }
        
    }
    
    func processGitHubLogin(request: Request, token: String) throws -> EventLoopFuture<ResponseEncodable> {
        
        return try GitHub.getUser(on: request)
            .and(GitHub.getEmails(on: request))
            .flatMap { userInfo, emailInfo in
                return User.query(on: request.db)
                    .filter(\.$username == userInfo.login)
                    .first()
                    .flatMap { foundUser in
                        if let existingUser = foundUser {
                            request.session.authenticate(existingUser)
                            return request.eventLoop
                                .future(request.redirect(to: "/"))
                        } else {
                            let user = User(name: userInfo.name,
                                            username: userInfo.login,
                                            password: UUID().uuidString,
                                            email: emailInfo[0].email)
                            return user.save(on: request.db)
                                .map {
                                    request.session.authenticate(user)
                                    return request.redirect(to: "/")
                                }
                        }
                    }
            }
        
    }
}

struct GoogleUserInfo: Content {
    let email: String
    let name: String
}

extension Google {
    static func getUser(on req: Request) throws -> EventLoopFuture<GoogleUserInfo> {
        var headers = HTTPHeaders()
        headers.bearerAuthorization = try BearerAuthorization(token: req.accessToken())
        
        let googleApiURL: URI = "https://www.googleapis.com/oauth2/v1/userinfo?alt=json"
        
        return req.client.get(googleApiURL, headers: headers)
            .flatMapThrowing { response in
                guard response.status == .ok else {
                    if response.status == .unauthorized {
                        throw Abort.redirect(to: "/login-google")
                    } else {
                        throw Abort(.internalServerError)
                    }
                }
                return try response.content
                    .decode(GoogleUserInfo.self)
            }
    }
}

struct GitHubUserInfo: Content {
    let name: String
    let login: String
}

struct GitHubEmailInfo: Content {
    let email: String
}

extension GitHub {
    static func getUser(on req: Request) throws -> EventLoopFuture<GitHubUserInfo> {
        var headers = HTTPHeaders()
        try headers.add(name: .authorization, value: "token \(req.accessToken())")
        headers.add(name: .userAgent, value: "vapor")
        
        let githubApiURL: URI = "https://api.github.com/user"
        
        return req.client.get(githubApiURL, headers: headers)
            .flatMapThrowing { response in
                guard response.status == .ok else {
                    if response.status == .unauthorized {
                        throw Abort.redirect(to: "/login-github")
                    } else {
                        throw Abort(.internalServerError)
                    }
                }
                return try response.content
                    .decode(GitHubUserInfo.self)
            }
    }
    
    static func getEmails(on request: Request) throws -> EventLoopFuture<[GitHubEmailInfo]> {
        var headers = HTTPHeaders()
        try headers.add(name: .authorization, value: "token \(request.accessToken())")
        headers.add(name: .userAgent, value: "vapor")
        
        let githubUserApiURL: URI = "https://api.github.com/user/emails"
        
        return request.client
            .get(githubUserApiURL, headers: headers)
            .flatMapThrowing { response in
                guard response.status == .ok else {
                    if response.status == .unauthorized {
                        throw Abort.redirect(to: "/login-github")
                    } else {
                        throw Abort(.internalServerError)
                    }
                }
                return try response.content
                    .decode([GitHubEmailInfo].self)
            }
    }
}
