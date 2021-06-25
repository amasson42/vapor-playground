import Fluent

struct CreateResetPasswordToken_v100: Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(ResetPasswordToken.v100.schema)
            .id()
            .field(ResetPasswordToken.v100.token, .string, .required)
            .field(ResetPasswordToken.v100.userID, .uuid, .required,
                   .references(User.v100.schema, User.v100.id))
            .unique(on: ResetPasswordToken.v100.token)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(ResetPasswordToken.v100.schema).delete()
    }
    
}

extension ResetPasswordToken {
    enum v100 {
        static let schema = "reset-password-tokens"
        
        static let id: FieldKey = "id"
        static let token: FieldKey = "token"
        static let userID: FieldKey = "userID"
    }
}
