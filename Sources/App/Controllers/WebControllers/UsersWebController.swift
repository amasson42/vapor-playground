import Vapor
import Fluent
import Leaf

struct UsersWebController: RouteCollection {
    
    let profileImagesFolder = "dynamic/profile/"
    
    func boot(routes: RoutesBuilder) throws {
        
        let group = routes.grouped("users")
        let protected = group.grouped(User.redirectMiddleware(path: "/login"))
        
        group.get(use: indexHandler)
        group.get(":userID", use: userHandler)
        
        protected.get(":userID", "addProfilePicture", use: addProfilePictureHandler)
        protected.on(
            .POST, ":userID", "addProfilePicture",
            body: .collect(maxSize: "10mb"),
            use: addProfilePicturePostHandler)
        
        group.get(":userID", "profilePicture", use: getUsersProfilePictureHandler)
        
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
        let authenticatedUser: User?
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
                            acronyms: acronyms,
                            authenticatedUser: req.auth.get(User.self))
                        
                        return req.view.render("Users/user", context)
                    }
            }
    }
    
    struct AddProfilePictureContext: BaseContext {
        let title = "Add Profile Picture"
        let userLoggedIn: Bool
        let username: String
    }
    
    func addProfilePictureHandler(_ req: Request) -> EventLoopFuture<View> {
        User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound)).flatMap { user in
                
                let context = AddProfilePictureContext(
                    userLoggedIn: req.auth.has(User.self),
                    username: user.name)
                
                return req.view.render("Users/addProfilePicture", context)
            }
    }
    
    struct ImageUploadData: Content {
        var picture: Data
    }
    
    func addProfilePicturePostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        let data = try req.content.decode(ImageUploadData.self)
        
        return User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                let userID: UUID
                do {
                    userID = try user.requireID()
                } catch {
                    return req.eventLoop.future(error: error)
                }
                let name = "\(userID)-\(UUID()).png"
                
                let path = req.application.directory.publicDirectory + profileImagesFolder + name
                
                return req.fileio.writeFile(.init(data: data.picture), at: path)
                    .flatMap {
                        user.profilePicture = name
                        return user.save(on: req.db)
                            .transform(to: req.redirect(to: "/users/\(userID)"))
                    }
            }
    }
    
    func getUsersProfilePictureHandler(_ req: Request) -> EventLoopFuture<Response> {
        User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing { user in
                guard let filename = user.profilePicture else {
                    throw Abort(.notFound)
                }
                
                let path = req.application.directory.publicDirectory + profileImagesFolder + filename
                
                return req.fileio.streamFile(at: path)
            }
    }
    
}
