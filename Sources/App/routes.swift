import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        return "It works!"
    }

    app.get("hello") { req -> String in
        return "Hello, world!"
    }
    
    let api = app.grouped("api")
    
    try api.register(collection: AcronymsController())
    try api.register(collection: UsersController())
    
}
