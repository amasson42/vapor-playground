import Vapor
import Fluent

final class Pokemon: Model, Content {
    static let schema = v110.schema
    
    @ID(key: v110.id)
    var id: UUID?
    
    @Field(key: v110.name)
    var name: String
    
    @Timestamp(key: v110.createdAt, on: .create)
    var createdAt: Date?
    
    @Timestamp(key: v110.updatedAt, on: .update)
    var updateAt: Date?
    
    init() {}
    
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
    
}
