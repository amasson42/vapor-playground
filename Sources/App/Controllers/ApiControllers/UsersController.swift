import Vapor
import Fluent

struct UsersController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped("users")
        
        group.get(use: handleGet)
        group.get(":userID", use: handleGetOne)
        group.get(":userID", "acronyms", use: handleGetAcronyms)
        group.get("mostRecentAcronym", use: handleGetMostRecentAcronymUser)
        
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = group.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        tokenAuthGroup.post(use: handlePost)
        tokenAuthGroup.delete(":userID", use: handleDelete)
        tokenAuthGroup.post(":userID", "restore", use: handlePostRestore)
        tokenAuthGroup.delete(":userID", "force", use: handleDeleteForce)
        
        let basicAuthMiddleware = User.authenticator()
        let basicAuthGroup = group.grouped(basicAuthMiddleware)
        
        basicAuthGroup.post("login", use: handleLogin)
        
    }
    
    func handlePost(_ req: Request) throws -> EventLoopFuture<User.Public> {
        let user = try req.content.decode(User.self)
        user.password = try Bcrypt.hash(user.password)
        return user.save(on: req.db).map { user.public() }
    }
    
    func handleLogin(_ req: Request) throws -> EventLoopFuture<Token> {
        let user = try req.auth.require(User.self)
        let token = try Token.generate(for: user)
        return token.save(on: req.db).map { token }
    }

    func handleDelete(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {

        let requestUser = try req.auth.require(User.self)
        guard requestUser.userType == .admin else {
            throw Abort(.forbidden)
        }

        return User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
            user.delete(on: req.db).transform(to: .noContent)
        }
    }

    func handlePostRestore(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let userID = try req.parameters.require("userID", as: UUID.self)

        return User.query(on: req.db)
            .withDeleted()
            .filter(\.$id == userID)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                user.restore(on: req.db).transform(to: .ok)
            }
    }

    func handleDeleteForce(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {

        let requestUser = try req.auth.require(User.self)
        guard requestUser.userType == .admin else {
            throw Abort(.forbidden)
        }
        
        return User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
            user.delete(force: true, on: req.db)
                .transform(to: .noContent)
        }
    }
    
    func handleGet(_ req: Request) -> EventLoopFuture<[User.Public]> {
        return User.query(on: req.db)
            .all()
            .map { $0.map{ $0.public() } }
    }
    
    func handleGetOne(_ req: Request) -> EventLoopFuture<User.Public> {
        return User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .map { $0.public() }
    }
    
    func handleGetAcronyms(_ req: Request) -> EventLoopFuture<[Acronym]> {
        return User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                user.$acronyms.get(on: req.db)
            }
    }
    
    func handleGetMostRecentAcronymUser(_ req: Request) -> EventLoopFuture<User.Public> {
        User.query(on: req.db)
            .join(Acronym.self, on: \Acronym.$user.$id == \User.$id)
            .sort(Acronym.self, \Acronym.$createdAt, .descending)
            .first()
            .unwrap(or: Abort(.internalServerError))
            .map { $0.public() }
    }

}
