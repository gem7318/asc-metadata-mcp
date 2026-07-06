import AppStoreConnect
import AppStoreAPI
import Foundation
import MCP

enum CreateExperimentTool {
    static let tool = Tool(
        name: "create_experiment",
        description:
            "Create a new product page optimization experiment (A/B test).",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "appId": .object(["type": "string", "description": "App Store app ID"]),
                "name": .object([
                    "type": "string",
                    "description": "Name of the experiment",
                ]),
                "platform": .object([
                    "type": "string",
                    "description": "Platform for the experiment",
                    "enum": .array([
                        .string("IOS"), .string("MAC_OS"),
                        .string("TV_OS"), .string("VISION_OS"),
                    ]),
                ]),
                "trafficProportion": .object([
                    "type": "integer",
                    "description":
                        "Percentage of traffic to allocate to the experiment (1-100)",
                ]),
                "dryRun": .object([
                    "type": "boolean",
                    "description":
                        "Preview changes without applying (default: false)",
                    "default": .bool(false),
                ]),
            ]),
            "required": .array([
                .string("appId"), .string("name"),
                .string("platform"), .string("trafficProportion"),
            ]),
        ])
    )

    static func handle(
        arguments: [String: Value]?,
        client: AppStoreConnectClient
    ) async throws -> CallTool.Result {
        guard let appId = arguments?["appId"]?.stringValue else {
            return .init(content: [.text(text: "Error: appId is required", annotations: nil, _meta: nil)], isError: true)
        }
        guard let name = arguments?["name"]?.stringValue else {
            return .init(content: [.text(text: "Error: name is required", annotations: nil, _meta: nil)], isError: true)
        }
        guard let platformStr = arguments?["platform"]?.stringValue else {
            return .init(
                content: [.text(text: "Error: platform is required", annotations: nil, _meta: nil)], isError: true)
        }
        guard let trafficProportion = arguments?["trafficProportion"]?.intValue else {
            return .init(
                content: [.text(text: "Error: trafficProportion is required", annotations: nil, _meta: nil)],
                isError: true)
        }
        let dryRun = arguments?["dryRun"]?.boolValue ?? false

        // Validate traffic proportion
        guard trafficProportion >= 1 && trafficProportion <= 100 else {
            return .init(
                content: [
                    .text(text: "Error: trafficProportion must be between 1 and 100", annotations: nil, _meta: nil)
                ],
                isError: true)
        }

        // Map platform
        let platform: Platform
        switch platformStr {
        case "IOS": platform = .iOS
        case "MAC_OS": platform = .macOS
        case "TV_OS": platform = .tvOS
        case "VISION_OS": platform = .visionOS
        default:
            return .init(
                content: [.text(text: "Error: Invalid platform '\(platformStr)'", annotations: nil, _meta: nil)],
                isError: true)
        }

        var resultDict: [String: Any] = [
            "appId": appId,
            "name": name,
            "platform": platformStr,
            "trafficProportion": trafficProportion,
        ]

        if dryRun {
            resultDict["status"] = "dry_run"
            let json = try JSONSerialization.data(
                withJSONObject: resultDict,
                options: [.prettyPrinted, .sortedKeys])
            return .init(
                content: [.text(text: String(data: json, encoding: .utf8) ?? "{}", annotations: nil, _meta: nil)])
        }

        // Create the experiment
        let request = AppStoreVersionExperimentV2CreateRequest(
            data: .init(
                attributes: .init(
                    name: name,
                    platform: platform,
                    trafficProportion: trafficProportion
                ),
                relationships: .init(
                    app: .init(data: .init(id: appId))
                )
            )
        )

        let response = try await client.send(
            Resources.v2.appStoreVersionExperiments.post(request)
        )
        let created = response.data
        resultDict["status"] = "created"
        resultDict["experimentId"] = created.id

        let json = try JSONSerialization.data(
            withJSONObject: resultDict, options: [.prettyPrinted, .sortedKeys])
        return .init(
            content: [.text(text: String(data: json, encoding: .utf8) ?? "{}", annotations: nil, _meta: nil)])
    }
}
