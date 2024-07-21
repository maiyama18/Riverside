import Payloads
import Vapor

func routes(_ app: Application) throws {
    app.post("feeds") { req in
        // TODO
        let requestBody = try req.content.decode(FeedsRequestBody.self)
        print(requestBody)
        return FeedsResponseBody(feeds: [:])
    }
}
