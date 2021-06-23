import Vapor
import Fluent
import Leaf

struct UsersWebController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        
        let group = routes.grouped("users")
        
        group.get(use: indexHandler)
        group.get(":userID", use: userHandler)
        
    }
    
    struct IndexContext: BaseContext {
        let title: String
        let userLoggedIn: Bool
        var users: [User]?
    }
    
    func indexHandler(_ req: Request) -> EventLoopFuture<View> {
        
        var context = IndexContext(
            title: "Users",
            userLoggedIn: req.auth.has(User.self))
        
        return User.query(on: req.db).all()
            .flatMap { users in
                context.users = users.isEmpty ? nil : users
                
                return req.view.render("Users/index", context)
            }
    }
    
    struct UserContext: BaseContext {
        let title: String
        let userLoggedIn: Bool
        let user: User
        let acronyms: [Acronym]
    }
    
    func userHandler(_ req: Request) -> EventLoopFuture<View> {
        
        return User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                user.$acronyms.get(on: req.db)
                    .flatMap { acronyms in
                        let context = UserContext(
                            title: user.name,
                            userLoggedIn: req.auth.has(User.self),
                            user: user,
                            acronyms: acronyms)
                        
                        return req.view.render("Users/user", context)
                    }
            }
    }
    
}
