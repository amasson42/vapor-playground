import Vapor
import Fluent

final class AcronymCategoryPivot: Model, Content {
    static let schema = v100.schema
    
    @ID
    var id: UUID?
    
    @Parent(key: v100.acronymID)
    var acronym: Acronym
    
    @Parent(key: v100.categoryID)
    var category: Category
    
    init() {}
    
    init(id: UUID? = nil,
         acronym: Acronym,
         category: Category) throws {
        self.id = id
        self.$acronym.id = try acronym.requireID()
        self.$category.id = try category.requireID()
    }
    
}
