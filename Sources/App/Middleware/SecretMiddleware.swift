import Vapor

final class SecretMiddleware: Middleware {
    
    let secret: String
    
    init(secret: String) {
        self.secret = secret
    }
    
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard request.headers.first(name: .xSecret) == secret else {
            return request.eventLoop.makeFailedFuture(Abort(.unauthorized, reason: "Incorrect X-Secret header."))
        }
        
        return next.respond(to: request)
    }
}

extension SecretMiddleware {
    static func detect() throws -> Self {
        return .init(secret: Environment.tilEnv.X_SECRET)
    }
}

extension HTTPHeaders.Name {
    static var xSecret: Self {
        return .init("X-Secret")
    }
}
