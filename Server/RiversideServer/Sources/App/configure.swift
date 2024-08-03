import Vapor
import Fluent
import FluentSQLiteDriver

public func configure(_ app: Application) async throws {
    app.http.server.configuration.port = Environment.get("PORT").flatMap(Int.init) ?? 8080
    
    app.http.client.configuration.timeout = .init(read: .seconds(15))
    
    app.databases.use(.sqlite(.file("db.sqlite3")), as: .sqlite)
    app.migrations.add(CreateFeed(), to: .sqlite)
    app.migrations.add(CreateEntry(), to: .sqlite)
    try await app.autoMigrate()

    try routes(app)
}
