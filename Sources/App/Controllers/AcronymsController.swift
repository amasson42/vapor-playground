import Vapor
import Fluent

struct AcronymsController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped("acronyms")
        
        group.post(use: handlePost)
        group.get(use: handleGet)
        group.get(":acronymID", use: handleGetOne)
        group.get("search", use: handleGetSearch)
        group.get("first", use: handleGetFirst)
        group.get("sorted", use: handleGetSorted)
        group.get("sorted", "first", use: handleGetSortedFirst)
        group.put(":acronymID", use: handlePutOne)
        group.delete(":acronymID", use: handleDeleteOne)
    }
    
    func handlePost(_ req: Request) throws -> EventLoopFuture<Acronym> {
        let acronym = try req.content.decode(Acronym.self)
        
        return acronym.save(on: req.db).map {
            acronym
        }
    }
    
    func handleGet(_ req: Request) -> EventLoopFuture<[Acronym]> {
        return Acronym.query(on: req.db).all()
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
    
    func handlePutOne(_ req: Request) throws -> EventLoopFuture<Acronym> {
        let updatedAcronym = try req.content.decode(Acronym.self)
        
        return Acronym.find(req.parameters.get("acronymID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { acronym in
                acronym.short = updatedAcronym.short
                acronym.long = updatedAcronym.long
                return updatedAcronym.save(on: req.db).map {
                    acronym
                }
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
    
}
