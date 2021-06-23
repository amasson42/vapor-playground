import Vapor
import Fluent
import Leaf

struct CategoriesWebController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        
        let group = routes.grouped("categories")
        
        group.get(use: indexHandler)
        group.get(":categoryID", use: categoryHandler)
        
    }
    
    struct IndexContext: BaseContext {
        let title: String
        let userLoggedIn: Bool
        var categories: [Category]?
    }
    
    func indexHandler(_ req: Request) -> EventLoopFuture<View> {
        var context = IndexContext(
            title: "Categories",
            userLoggedIn: req.auth.has(User.self))
        
        return Category.query(on: req.db).all()
            .flatMap { categories in
                context.categories = categories.isEmpty ? nil : categories
                
                return req.view.render("Categories/index", context)
            }
    }
    
    struct CategoryContext: BaseContext {
        let title: String
        let userLoggedIn: Bool
        let category: Category
        let acronyms: [Acronym]
    }
    
    func categoryHandler(_ req: Request) -> EventLoopFuture<View> {
        return Category.find(req.parameters.get("categoryID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { category in
                category.$acronyms.get(on: req.db)
                    .flatMap { acronyms in
                        let context = CategoryContext(
                            title: category.name,
                            userLoggedIn: req.auth.has(User.self),
                            category: category,
                            acronyms: acronyms)
                        
                        return req.view.render("Categories/category", context)
                    }
            }
    }
    
}
