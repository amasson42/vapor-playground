import Fluent

struct CreateToken: Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Token.schema)
            .id()
            .field("value", .string, .required)
            .field("userID", .uuid, .required,
                   .references(User.schema, "id",
                               onDelete: .cascade))
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Token.schema).delete()
    }
    
}
