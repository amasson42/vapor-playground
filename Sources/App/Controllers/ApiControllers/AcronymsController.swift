import Vapor
import Fluent
import SQLKit

struct AcronymsController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped("acronyms")
        
        group.get(use: handleGet)
        group.get(":acronymID", use: handleGetOne)
        group.get("search", use: handleGetSearch)
        group.get("first", use: handleGetFirst)
        group.get("sorted", use: handleGetSorted)
        group.get("sorted", "first", use: handleGetSortedFirst)
        group.get("sorted", "recent", use: handleGetSortedRecent)
        group.get("sorted", "recent", "first", use: handleGetSortedRecentFirst)
        group.get(":acronymID", "user", use: handleGetUser)
        group.get(":acronymID", "categories", use: handleGetCategories)
        
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = group.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        tokenAuthGroup.post(use: handlePost)
        tokenAuthGroup.put(":acronymID", use: handlePutOne)
        tokenAuthGroup.delete(":acronymID", use: handleDeleteOne)
        tokenAuthGroup.post(":acronymID", "categories", ":categoryID", use: handlePostAddCategory)
        tokenAuthGroup.delete(":acronymID", "categories", ":categoryID", use: handleDeleteCategories)
        
    }
    
    func handlePost(_ req: Request) throws -> EventLoopFuture<Acronym> {
        let data = try req.content.decode(CreateAcronymData.self)
        
        let user = try req.auth.require(User.self)
        
        let acronym = try Acronym(
            short: data.short,
            long: data.long,
            userID: user.requireID())
        
        return acronym.save(on: req.db).map { acronym }
    }
    
    func handleGet(_ req: Request) -> EventLoopFuture<[Acronym]> {
        // Because we like it raw
        if Bool.random(),
            let sql = req.db as? SQLDatabase {
            return sql.raw("SELECT * FROM acronyms")
                .all(decoding: Acronym.self)
        } else {
            return Acronym.query(on: req.db).all()
        }
    }
    
    func handleGetOne(_ req: Request) -> EventLoopFuture<Acronym> {
        return Acronym.find(req.parameters.get("acronymID"), on: req.db)
            .unwrap(or: Abort(.notFound))
    }
    
    func handleGetSearch(_ req: Request) throws -> EventLoopFuture<[Acronym]> {
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        
        return Acronym.query(on: req.db).group(.or) { or in
            or.filter(\.$short == searchTerm)
            or.filter(\.$long == searchTerm)
        }
        .all()
    }
    
    func handleGetFirst(_ req: Request) -> EventLoopFuture<Acronym> {
        return Acronym.query(on: req.db)
            .first()
            .unwrap(or: Abort(.notFound))
    }
    
    func handleGetSorted(_ req: Request) -> EventLoopFuture<[Acronym]> {
        return Acronym.query(on: req.db)
            .sort(\.$short, .ascending)
            .all()
    }
    
    func handleGetSortedFirst(_ req: Request) -> EventLoopFuture<Acronym> {
        return Acronym.query(on: req.db)
            .sort(\.$short, .ascending)
            .first()
            .unwrap(or: Abort(.notFound))
    }

    func handleGetSortedRecent(_ req: Request) -> EventLoopFuture<[Acronym]> {
        Acronym.query(on: req.db)
            .sort(\.$updatedAt, .descending)
            .all()
    }
    
    func handleGetSortedRecentFirst(_ req: Request) -> EventLoopFuture<Acronym> {
        Acronym.query(on: req.db)
            .sort(\.$updatedAt, .descending)
            .first()
            .unwrap(or: Abort(.notFound))
    }

    func handleGetUser(_ req: Request) -> EventLoopFuture<User.Public> {
        Acronym.find(req.parameters.get("acronymID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { acronym in
                acronym.$user.get(on: req.db).map { $0.public() }
            }
    }
    
    func handlePutOne(_ req: Request) throws -> EventLoopFuture<Acronym> {
        let updateData = try req.content.decode(CreateAcronymData.self)
        
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        
        return Acronym.find(req.parameters.get("acronymID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { acronym in
                acronym.short = updateData.short
                acronym.long = updateData.long
                acronym.$user.id = userID
                return acronym.save(on: req.db).map { acronym }
            }
    }
    
    func handleDeleteOne(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return Acronym.find(req.parameters.get("acronymID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap {
                $0.delete(on: req.db)
                    .transform(to: .noContent)
            }
    }
    
    func handlePostAddCategory(_ req: Request) -> EventLoopFuture<HTTPStatus> {
        let acronymQuery = Acronym.find(req.parameters.get("acronymID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        
        let categoryQuery = Category.find(req.parameters.get("categoryID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        
        return acronymQuery.and(categoryQuery)
            .flatMap {
                acronym, category in
                acronym
                    .$categories
                    .attach(category, on: req.db)
                    .transform(to: .created)
            }
    }
    
    func handleGetCategories(_ req: Request) -> EventLoopFuture<[Category]> {
        Acronym.find(req.parameters.get("acronymID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { acronym in
                acronym.$categories.query(on: req.db).all()
            }
    }
    
    func handleDeleteCategories(_ req: Request) -> EventLoopFuture<HTTPStatus> {
        let acronymQuery = Acronym.find(req.parameters.get("acronymID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        let categoryQuery = Category.find(req.parameters.get("categoryID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        
        return acronymQuery.and(categoryQuery)
            .flatMap { acronym, category in
                acronym
                    .$categories
                    .detach(category, on: req.db)
                    .transform(to: .noContent)
            }
    }
    
}

struct CreateAcronymData: Content {
    let short: String
    let long: String
}
