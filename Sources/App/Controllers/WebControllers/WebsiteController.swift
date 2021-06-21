import Vapor
import Fluent
import Leaf

struct WebsiteController: RouteCollection {
    
    let homeController = HomeWebController()
    let usersController = UsersWebController()
    let acronymsController = AcronymsWebController()
    let categoriesController = CategoriesWebController()

    func boot(routes: RoutesBuilder) throws {
        let authSessionRoutes = routes.grouped(User.sessionAuthenticator())
        let credentialsAuthRoutes = authSessionRoutes.grouped(User.credentialsAuthenticator())
        let protectedRoutes = authSessionRoutes.grouped(User.redirectMiddleware(path: "/login"))

        authSessionRoutes.get(use: self.homeController.indexHandler)
        authSessionRoutes.get("register", use: self.homeController.registerHandler)
        authSessionRoutes.post("register", use: self.homeController.registerPostHandler)
        authSessionRoutes.get("login", use: self.homeController.loginHandler)
        credentialsAuthRoutes.post("login", use: self.homeController.loginPostHandler)
        authSessionRoutes.post("logout", use: self.homeController.logoutHandler)

        // MARK: /users
        authSessionRoutes.get("users", use: self.usersController.indexHandler)
        authSessionRoutes.get("users", ":userID", use: self.usersController.userHandler)

        // MARK: /acronyms
        authSessionRoutes.get("acronyms", use: self.acronymsController.indexHandler)
        authSessionRoutes.get("acronyms", ":acronymID", use: self.acronymsController.acronymHandler)
        protectedRoutes.get("acronyms", "create", use: self.acronymsController.createAcronymHandler)
        protectedRoutes.post("acronyms", "create", use: self.acronymsController.createAcronymPostHandler)
        protectedRoutes.get("acronyms", ":acronymID", "edit", use: self.acronymsController.editAcronymHandler)
        protectedRoutes.post("acronyms", ":acronymID", "edit", use: self.acronymsController.editAcronymPostHandler)
        protectedRoutes.post("acronyms", ":acronymID", "delete", use: self.acronymsController.deleteAcronymHandler)

        // MARK: /categories
        authSessionRoutes.get("categories", use: self.categoriesController.indexHandler)
        authSessionRoutes.get("categories", ":categoryID", use: self.categoriesController.categoryHandler)

    }
}
