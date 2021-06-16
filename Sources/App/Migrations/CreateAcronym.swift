import Fluent

struct CreateAcronym: Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Acronym.schema)
            .id()
            .field("short", .string, .required)
            .field("long", .string, .required)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Acronym.schema).delete()
    }
    
}
