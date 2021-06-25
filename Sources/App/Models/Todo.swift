import Vapor
import Fluent

final class Todo: Model, Content {
    static let schema = v110.schema
    
    @ID
    var id: UUID?
    
    @Field(key: v110.title)
    var title: String
    
    init() {}
    
    init(id: UUID? = nil, title: String) {
        self.id = id
        self.title = title
    }
}
