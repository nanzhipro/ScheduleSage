import XCTest
import Vapor
@testable import ScheduleSage

final class RevenueCatWebhookHandlerTests: XCTestCase {
    
    var app: Application!
    var handler: RevenueCatWebhookHandler!
    
    override func setUp() {
        super.setUp()
        app = Application(.testing)
        handler = RevenueCatWebhookHandler()
    }
    
    override func tearDown() {
        app.shutdown()
        app = nil
        handler = nil
        super.tearDown()
    }
    
    func testHandleWebhookWithValidSignature() throws {
        let req = Request(application: app, on: app.eventLoopGroup.next())
        req.headers.add(name: "X-Signature", value: "valid_signature")
        
        let event = RevenueCatEvent(type: .initialPurchase, data: .init(userId: "user1", productId: "product1", purchaseDate: Date(), expirationDate: nil))
        try req.content.encode(event)
        
        let response = try handler.handleWebhook(req).wait()
        XCTAssertEqual(response, .ok)
    }
    
    func testHandleWebhookWithInvalidSignature() throws {
        let req = Request(application: app, on: app.eventLoopGroup.next())
        req.headers.add(name: "X-Signature", value: "invalid_signature")
        
        let event = RevenueCatEvent(type: .initialPurchase, data: .init(userId: "user1", productId: "product1", purchaseDate: Date(), expirationDate: nil))
        try req.content.encode(event)
        
        let response = try handler.handleWebhook(req).wait()
        XCTAssertEqual(response, .unauthorized)
    }
    
    func testHandleInitialPurchase() throws {
        let event = RevenueCatEvent(type: .initialPurchase, data: .init(userId: "user1", productId: "product1", purchaseDate: Date(), expirationDate: nil))
        try handler.handleInitialPurchase(event)
        // Add assertions to verify the initial purchase handling logic
    }
    
    func testHandleRenewal() throws {
        let event = RevenueCatEvent(type: .renewal, data: .init(userId: "user1", productId: "product1", purchaseDate: Date(), expirationDate: nil))
        try handler.handleRenewal(event)
        // Add assertions to verify the renewal handling logic
    }
    
    func testHandleCancellation() throws {
        let event = RevenueCatEvent(type: .cancellation, data: .init(userId: "user1", productId: "product1", purchaseDate: Date(), expirationDate: nil))
        try handler.handleCancellation(event)
        // Add assertions to verify the cancellation handling logic
    }
}
