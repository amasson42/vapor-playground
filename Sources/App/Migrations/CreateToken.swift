import Fluent

struct CreateToken_v100: Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Token.v100.schema)
            .id()
            .field(Token.v100.value, .string, .required)
            .field(Token.v100.userID, .uuid, .required,
                   .references(User.v100.schema, User.v100.id,
                               onDelete: .cascade))
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Token.v100.schema).delete()
    }
    
}

extension Token {
    enum v100 {
        static let schema = "tokens"
        
        static let id: FieldKey = "id"
        static let value: FieldKey = "value"
        static let userID: FieldKey = "userID"
    }
}
