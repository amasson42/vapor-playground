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
    let api = app.grouped("api")
    
    try api.register(collection: AcronymsController())
    try api.register(collection: UsersController())
    try api.register(collection: CategoriesController())
    
    // MARK: Web
    
//    try app.register(collection: HomeWebController())
//    try app.register(collection: AcronymsWebController())
//    try app.register(collection: UsersWebController())
//    try app.register(collection: CategoriesWebController())
    try app.register(collection: WebsiteController())
    try app.register(collection: ImperialController())
    
}
