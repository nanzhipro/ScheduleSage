import Vapor

struct RevenueCatWebhookHandler {
    private let logger = Logger(label: "com.tiwenlab.schedulesage.RevenueCatWebhookHandler")

    func handleWebhook(_ req: Request) async throws -> HTTPStatus {
        let signature = req.headers["X-Signature"].first
        guard let signature = signature, verifySignature(signature, for: req) else {
            logger.error("Invalid signature")
            return .unauthorized
        }

        let event = try req.content.decode(RevenueCatEvent.self)
        switch event.type {
        case .initialPurchase:
            try await handleInitialPurchase(event)
        case .renewal:
            try await handleRenewal(event)
        case .cancellation:
            try await handleCancellation(event)
        }

        return .ok
    }

    private func verifySignature(_ signature: String, for req: Request) -> Bool {
        // Implement signature verification logic here
        return true
    }

    private func handleInitialPurchase(_ event: RevenueCatEvent) async throws {
        // Implement initial purchase handling logic here
    }

    private func handleRenewal(_ event: RevenueCatEvent) async throws {
        // Implement renewal handling logic here
    }

    private func handleCancellation(_ event: RevenueCatEvent) async throws {
        // Implement cancellation handling logic here
    }
}

struct RevenueCatEvent: Content {
    let type: EventType
    let data: EventData

    enum EventType: String, Codable {
        case initialPurchase = "INITIAL_PURCHASE"
        case renewal = "RENEWAL"
        case cancellation = "CANCELLATION"
    }

    struct EventData: Codable {
        let userId: String
        let productId: String
        let purchaseDate: Date
        let expirationDate: Date?
    }
}
