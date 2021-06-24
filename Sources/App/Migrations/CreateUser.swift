import Fluent
import Vapor

struct CreateUser: Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.schema)
            .id()
            .field("name", .string, .required)
            .field("username", .string, .required)
            .field("password", .string, .required)
            .field("email", .string, .required)
            .field("profilePicture", .string)
            .unique(on: "username")
            .unique(on: "email")
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.schema).delete()
    }
    
}

struct CreateAdminUser: Migration {
    
    public static let defaultName = "Admin"
    public static let defaultUsername = "admin"
    public static let defaultPassword = "password"
    public static let defaultEmail = "giantwow3896@gmail.com"
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let passwordHash: String
        do {
            passwordHash = try Bcrypt.hash(Self.defaultPassword)
        } catch {
            return database.eventLoop.future(error: error)
        }
        
        let user = User(
            name: Self.defaultName,
            username: Self.defaultUsername,
            password: passwordHash,
            email: Self.defaultEmail)
        
        return user.save(on: database)
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        User.query(on: database)
            .filter(\.$username == Self.defaultUsername)
            .delete()
    }
    
}
