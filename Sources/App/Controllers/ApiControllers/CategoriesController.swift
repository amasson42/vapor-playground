import Vapor
import Fluent

struct CategoriesController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped("categories")
        group.get(use: handleGet)
        group.get(":categoryID", use: handleGetOne)
        group.get("pivots", use: handleGetPivots)
        group.get(":categoryID", "acronyms", use: handleGetAcronyms)
        group.get("all", use: handleGetAll)

        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = group.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        tokenAuthGroup.post(use: handlePost)
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

    struct CategoryWithAcronyms: Content {
        let id: UUID?
        let name: String
        let acronyms: [AcronymWithUser]
        struct AcronymWithUser: Content {
            let id: UUID?
            let short: String
            let long: String
            let user: User.Public
        }
    }

    func handleGetAll(_ req: Request) -> EventLoopFuture<[CategoryWithAcronyms]> {
        Category.query(on: req.db)
            .with(\.$acronyms) { acronyms in
                acronyms.with(\.$user)
            }.all().map { categories in
                categories.map { category in
                    let categoryAcronyms = category.acronyms.map { acronym in
                        CategoryWithAcronyms.AcronymWithUser(
                            id: acronym.id,
                            short: acronym.short,
                            long: acronym.long,
                            user: acronym.user.public())
                    }

                    return CategoryWithAcronyms(
                        id: category.id,
                        name: category.name,
                        acronyms: categoryAcronyms)
                }
            }
    }
    
}
