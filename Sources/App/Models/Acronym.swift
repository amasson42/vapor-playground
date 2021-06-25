import Vapor
import Fluent

final class Acronym: Model, Content {
    static let schema = v100.schema
    
    @ID
    var id: UUID?
    
    @Field(key: v100.short)
    var short: String
    
    @Field(key: v100.long)
    var long: String
    
    @Parent(key: v100.userID)
    var user: User
    
    @Siblings(through: AcronymCategoryPivot.self,
              from: \.$acronym,
              to: \.$category)
    var categories: [Category]
    
    init() {}
    
    init(id: UUID? = nil, short: String, long: String, userID: User.IDValue) {
        self.id = id
        self.short = short
        self.long = long
        self.$user.id = userID
    }
    
}
