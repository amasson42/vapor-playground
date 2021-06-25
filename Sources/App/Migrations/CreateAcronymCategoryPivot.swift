import Fluent

struct CreateAcronymCategoryPivot_v100: Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(AcronymCategoryPivot.v100.schema)
            .id()
            .field(AcronymCategoryPivot.v100.acronymID, .uuid, .required,
                   .references(Acronym.v100.schema, Acronym.v100.id,
                               onDelete: .cascade))
            .field(AcronymCategoryPivot.v100.categoryID, .uuid, .required,
                   .references(Category.v100.schema, Category.v100.id,
                               onDelete: .cascade))
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(AcronymCategoryPivot.v100.schema).delete()
    }
    
}

extension AcronymCategoryPivot {
    enum v100 {
        static let schema = "acronym-category-pivot"
        
        static let id: FieldKey = "id"
        static let acronymID: FieldKey = "acronymID"
        static let categoryID: FieldKey = "categoryID"
    }
}
