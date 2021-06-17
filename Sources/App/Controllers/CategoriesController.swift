import Vapor
import Fluent

struct CategoriesController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped("categories")
        group.post(use: handlePost)
        group.get(use: handleGet)
        group.get(":categoryID", use: handleGetOne)
        group.get("pivots", use: handleGetPivots)
    }
    
    func handlePost(_ req: Request) throws -> EventLoopFuture<Category> {
        let category = try req.content.decode(Category.self)
        return category.save(on: req.db).map { category }
    }
    
    func handleGet(_ req: Request) -> EventLoopFuture<[Category]> {
        return Category.query(on: req.db).all()
    }
    
    func handleGetOne(_ req: Request) -> EventLoopFuture<Category> {
        return Category.find(req.parameters.get("categoryID"), on: req.db)
            .unwrap(or: Abort(.notFound))
    }
    
    func handleGetPivots(_ req: Request) -> EventLoopFuture<[AcronymCategoryPivot]> {
        return AcronymCategoryPivot.query(on: req.db)
            .all()
    }
    
    func handleGetAcronyms(_ req: Request) -> EventLoopFuture<[Acronym]> {
        return Category.find(req.parameters.get("categoryID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { category in
                category.$acronyms.get(on: req.db)
            }
    }
    
}
