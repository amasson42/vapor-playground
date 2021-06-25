import Fluent

struct CreateCategory_v100: Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Category.v100.schema)
            .id()
            .field(Category.v100.name, .string, .required)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Category.v100.schema).delete()
    }
    
}

extension Category {
    enum v100 {
        static let schema = "categories"
        
        static let id: FieldKey = "id"
        static let name: FieldKey = "name"
    }
}
