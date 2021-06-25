import Fluent
import Vapor

struct CreateUser_v100: Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.v100.schema)
            .id()
            .field(User.v100.name, .string, .required)
            .field(User.v100.username, .string, .required)
            .field(User.v100.password, .string, .required)
            .field(User.v100.email, .string, .required)
            .field(User.v100.profilePicture, .string)
            .unique(on: User.v100.username)
            .unique(on: User.v100.email)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.v100.schema).delete()
    }
    
}

struct CreateUser_v110: Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.v100.schema)
            .field(User.v110.twitterUrl, .string)
            .update()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.v100.schema)
            .deleteField(User.v110.twitterUrl)
            .update()
    }
    
}

extension User {
    enum v100 {
        static let schema = "users"
        
        static let id: FieldKey = "id"
        static let name: FieldKey = "name"
        static let username: FieldKey = "username"
        static let password: FieldKey = "password"
        static let email: FieldKey = "email"
        static let profilePicture: FieldKey = "profilePicture"
    }
    
    enum v110 {
        static let twitterUrl: FieldKey = "twitterUrl"
    }
}

// CreateAdminUser does not need versioning as it's not meant for production
struct CreateAdminUser: Migration {
    
    public static let defaultName = "Admin"
    public static let defaultUsername = "admin"
    public static let defaultPassword = "password"
    public static let defaultEmail = "giantwow3896@gmail.com"
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        
        do {
            return try User(
                name: Self.defaultName,
                username: Self.defaultUsername,
                password: Bcrypt.hash(Self.defaultPassword),
                email: Self.defaultEmail)
                .save(on: database)
        } catch {
            return database.eventLoop.future(error: error)
        }
        
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        User.query(on: database)
            .filter(\.$username == Self.defaultUsername)
            .delete()
    }
    
}
