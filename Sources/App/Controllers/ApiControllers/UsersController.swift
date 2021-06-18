import Vapor
import Fluent

struct UsersController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped("users")
        group.post(use: handlePost)
        group.get(use: handleGet)
        group.get(":userID", use: handleGetOne)
        group.get(":userID", "acronyms", use: handleGetAcronyms)
    }
    
    func handlePost(_ req: Request) throws -> EventLoopFuture<User> {
        let user = try req.content.decode(User.self)
        return user.save(on: req.db).map { user }
    }
    
    func handleGet(_ req: Request) -> EventLoopFuture<[User]> {
        return User.query(on: req.db).all()
    }
    
    func handleGetOne(_ req: Request) -> EventLoopFuture<User> {
        return User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
    }
    
    func handleGetAcronyms(_ req: Request) -> EventLoopFuture<[Acronym]> {
        return User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                user.$acronyms.get(on: req.db)
            }
    }
    
}