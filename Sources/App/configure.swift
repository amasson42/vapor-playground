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
    
    app.databases.use(.postgres(
        hostname: Environment.tilEnv.DATABASE_HOST,
        port: Int(Environment.tilEnv.DATABASE_PORT)!,
        username: Environment.tilEnv.DATABASE_USERNAME,
        password: Environment.tilEnv.DATABASE_PASSWORD,
        database: Environment.tilEnv.DATABASE_NAME
    ), as: .psql)
    
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
    
//    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    
    
    /// The order of this migrations call matter.
    /// It will create database tables and if there is relationships, then they have to exist in correct order
    app.migrations.add(CreateUser())
    app.migrations.add(CreateAcronym())
    app.migrations.add(CreateCategory())
    app.migrations.add(CreateAcronymCategoryPivot())
    
    app.logger.logLevel = .debug
    
    try app.autoMigrate().wait()
    
    // register routes
    try routes(app)
}
