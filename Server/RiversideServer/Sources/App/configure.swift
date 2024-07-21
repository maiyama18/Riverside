import Vapor

public func configure(_ app: Application) async throws {
    app.http.server.configuration.port = Environment.get("PORT").flatMap(Int.init) ?? 8080
    try routes(app)
}
