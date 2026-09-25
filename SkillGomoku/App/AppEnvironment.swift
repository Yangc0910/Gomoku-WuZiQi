import Foundation

struct AppEnvironment {
    var avatarService: any AvatarStoring = AvatarService()
    var cameraAvailability: any CameraAvailabilityProviding = DeviceCameraAvailability()
    var ruleEngine = RuleEngine()
}
