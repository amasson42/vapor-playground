import Fluent
import Vapor

func routes(_ app: Application) throws {
    
    app.get("hello", ":name", ":time") { req -> EventLoopFuture<String> in
        let promise = req.eventLoop.makePromise(of: String.self)
        let name = req.parameters.get("name")!
        let time = req.parameters.get("time")!
        
        // A good shell injection...
        // This is actually the worst security breach we can imagine ! :D
        let shellLine = "sleep \(Int(time) ?? 1); echo Hello \(name.debugDescription)"
        try shell(shellLine) {
            (stdout, _, _) in
            promise.succeed(stdout)
        }
        
        return promise.futureResult
    }
    
    // MARK: Api
    let api = app.grouped("api", "v1")
    
    try api.register(collection: AcronymsController())
    try api.register(collection: UsersController())
    try api.register(collection: CategoriesController())
    
    // MARK: Web
    
    let web = app.grouped(User.sessionAuthenticator())
    
    try web.register(collection: HomeWebController())
    try web.register(collection: AcronymsWebController())
    try web.register(collection: UsersWebController())
    try web.register(collection: CategoriesWebController())
    
    // As app so the login is not required
    try app.register(collection: ImperialController())

}
