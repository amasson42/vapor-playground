import Fluent
import FluentPostgresDriver
import FluentSQLiteDriver
import FluentMySQLDriver
import FluentMongoDriver
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    // MARK: Use database
    
//    app.databases.use(.postgres(
//        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
//        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? PostgresConfiguration.ianaPortNumber,
//        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
//        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
//        database: Environment.get("DATABASE_NAME") ?? "vapor_database"
//    ), as: .psql)
    
//    app.databases.use(.mysql(
//        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
//        username: Environment.get("DATABASE_USERNAME")
//            ?? "vapor_username",
//        password: Environment.get("DATABASE_PASSWORD")
//            ?? "vapor_password",
//        database: Environment.get("DATABASE_NAME")
//            ?? "vapor_database",
//        tlsConfiguration: .forClient(certificateVerification: .none)
//    ), as: .mysql)
    
//    try app.databases.use(.mongo(connectionString: "mongodb://localhost:27017/vapor"),
//                              as: .mongo)
    
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    
    app.migrations.add(CreateAcronym())
    
    app.logger.logLevel = .debug
    
    try app.autoMigrate().wait()

    // register routes
    try routes(app)
}
