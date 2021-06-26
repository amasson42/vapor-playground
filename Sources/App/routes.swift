import Fluent
import Vapor

func routes(_ app: Application) throws {
    
    try app.group(SecretMiddleware.detect()) { secretGroup in
        try secretGroup.register(collection: TodosController())
    }
    
    // MARK: Api
    let api = app.grouped("api", "v1")
    
    try api.register(collection: AcronymsController())
    try api.register(collection: UsersController())
    try api.register(collection: CategoriesController())
    try api.register(collection: PokemonsController())
    
    // MARK: Web
    
    let web = app.grouped(User.sessionAuthenticator())
    
    try web.register(collection: HomeWebController())
    try web.register(collection: AcronymsWebController())
    try web.register(collection: UsersWebController())
    try web.register(collection: CategoriesWebController())
    
    // As app so the login is not required
    try app.register(collection: ImperialController())

}
