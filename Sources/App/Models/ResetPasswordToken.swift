import Vapor
import Fluent

final class ResetPasswordToken: Model, Content {
    static let schema = v100.schema
    
    @ID
    var id: UUID?
    
    @Field(key: v100.token)
    var token: String
    
    @Parent(key: v100.userID)
    var user: User
    
    init() {}
    
    init(id: UUID? = nil, token: String, userID: User.IDValue) {
        self.id = id
        self.token = token
        self.$user.id = userID
    }
}
