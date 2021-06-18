import Vapor
import Fluent
import Leaf

struct AcronymsWebController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped("acronyms")
        
        group.get(use: indexHandler)
        group.get(":acronymID", use: acronymHandler)
        group.get("create", use: createAcronymHandler)
        group.post("create", use: createAcronymPostHandler)
        
    }
    
    // path: /acronyms
    struct IndexContext: BaseContext {
        let title: String
        var acronyms: [Acronym]?
    }
    
    func indexHandler(_ req: Request) -> EventLoopFuture<View> {
        
        var context = IndexContext(title: "Acronyms")
        
        return Acronym.query(on: req.db)
            .all()
            .flatMap { acronyms in
            context.acronyms = acronyms.isEmpty ? nil : acronyms
            
            return req.view.render("Acronyms/index", context)
        }
    }
    
    // path: /acronyms/:acronymID
    struct AcronymContext: BaseContext {
        let title: String
        let acronym: Acronym
        let user: User
        let categories: [Category]
    }
    
    func acronymHandler(_ req: Request) -> EventLoopFuture<View> {
        
        return Acronym.find(req.parameters.get("acronymID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { acronym in
                acronym.$user.get(on: req.db)
                    .and(acronym.$categories.get(on: req.db))
                    .flatMap { user, categories in
                    let context = AcronymContext(
                        title: acronym.short,
                        acronym: acronym,
                        user: user,
                        categories: categories)
                    return req.view.render("Acronyms/acronym", context)
                }
            }
    }
    
    struct CreateAcronymContext: BaseContext {
        let title = "Create An Acronym"
        let users: [User]
    }
    
    func createAcronymHandler(_ req: Request) -> EventLoopFuture<View> {
        
        return User.query(on: req.db).all().flatMap { users in
            let context = CreateAcronymContext(users: users)
            
            return req.view.render("Acronyms/createAcronym", context)
        }
        
    }
    
    func createAcronymPostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        
        let data = try req.content.decode(CreateAcronymData.self)
        
        let acronym = Acronym(
            short: data.short,
            long: data.long,
            userID: data.userID)
        
        return acronym.save(on: req.db)
            .flatMapThrowing {
                guard let id = acronym.id else {
                    throw Abort(.internalServerError)
                }
                
                return req.redirect(to: "/acronyms/\(id)")
            }
    }
    
}
