import Fluent

struct CreateTodo_v110: Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Todo.v110.schema)
            .id()
            .field(Todo.v110.title, .string, .required)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Todo.v110.schema)
            .delete()
    }
    
}

extension Todo {
    enum v110 {
        static let schema = "todos"
        
        static let id: FieldKey = "id"
        static let title: FieldKey = "title"
    }
}
