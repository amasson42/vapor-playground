import Fluent

struct CreatePokemon_v110: Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Pokemon.v110.schema)
            .id()
            .field(Pokemon.v110.name, .string, .required)
            .field(Pokemon.v110.createdAt, .datetime)
            .field(Pokemon.v110.updatedAt, .datetime)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Pokemon.v110.schema).delete()
    }
    
}

extension Pokemon {
    enum v110 {
        static let schema = "pokemons"
        
        static let id: FieldKey = "id"
        static let name: FieldKey = "name"
        static let createdAt: FieldKey = "created_at"
        static let updatedAt: FieldKey = "updated_at"
    }
}
