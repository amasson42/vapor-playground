import Fluent

struct CreateAcronym_v100: Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Acronym.v100.schema)
            .id()
            .field(Acronym.v100.short, .string, .required)
            .field(Acronym.v100.long, .string, .required)
            .field(Acronym.v100.userID, .uuid, .required,
                   .references(User.v100.schema, User.v100.id))
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Acronym.v100.schema).delete()
    }
    
}

extension Acronym {
    enum v100 {
        static let schema = "acronyms"
        
        static let id: FieldKey = "id"
        static let short: FieldKey = "short"
        static let long: FieldKey = "long"
        static let userID: FieldKey = "userID"
    }
}
