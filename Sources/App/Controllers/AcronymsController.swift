import Vapor
import Fluent

struct AcronymsController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let acronyms = routes.grouped("acronyms")
        
        acronyms.post(use: handlePost)
        acronyms.get(use: handleGet)
        acronyms.get(":acronymID", use: handleGetOne)
        acronyms.get("search", use: handleGetSearch)
        acronyms.get("first", use: handleGetFirst)
        acronyms.get("sorted", use: handleGetSorted)
        acronyms.get("sorted", "first", use: handleGetSortedFirst)
        acronyms.put(":acronymID", use: handlePutOne)
        acronyms.delete(":acronymID", use: handleDeleteOne)
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
