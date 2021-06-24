import Fluent

struct CreateResetPasswordToken: Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(ResetPasswordToken.schema)
            .id()
            .field("token", .string, .required)
            .field("userID", .uuid, .required, .references(User.schema, "id"))
            .unique(on: "token")
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(ResetPasswordToken.schema).delete()
    }
    
}
