import Fluent
import Vapor

struct CreateUser: Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.schema)
            .id()
            .field("name", .string, .required)
            .field("username", .string, .required)
            .field("password", .string, .required)
            .unique(on: "username")
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.schema).delete()
    }
    
}

struct CreateAdminUser: Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let passwordHash: String
        do {
            passwordHash = try Bcrypt.hash("password")
        } catch {
            return database.eventLoop.future(error: error)
        }
        
        let user = User(
            name: "Admin",
            username: "admin",
            password: passwordHash)
        
        return user.save(on: database)
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        User.query(on: database)
            .filter(\.$username == "admin")
            .delete()
        
    }
    
}
