import Vapor
import Fluent

final class Category: Model, Content {
    static let schema = v100.schema
    
    @ID
    var id: UUID?
    
    @Field(key: v100.name)
    var name: String
    
    @Siblings(through: AcronymCategoryPivot.self,
              from: \.$category,
              to: \.$acronym)
    var acronyms: [Acronym]
    
    init() {}
    
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

extension Category {
    static func addCategory(_ name: String,
                            to acronym: Acronym,
                            on req: Request) -> EventLoopFuture<Void> {
        return Category.query(on: req.db)
            .filter(\.$name == name)
            .first()
            .flatMap { foundCategory in
                if let existingCategory = foundCategory {
                    return acronym.$categories
                        .attach(existingCategory, on: req.db)
                } else {
                    let category = Category(name: name)
                    
                    return category.save(on: req.db).flatMap {
                        acronym.$categories
                            .attach(category, on: req.db)
                    }
                }
            }
    }
}
