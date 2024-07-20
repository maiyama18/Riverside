import Vapor

struct SampleResponse: Content {
    let message: String
}

func routes(_ app: Application) throws {
    app.get { req in
        SampleResponse(message: "Hello, world!")
    }
}
