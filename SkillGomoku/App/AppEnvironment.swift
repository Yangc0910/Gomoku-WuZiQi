import Foundation

struct AppEnvironment {
    var avatarService: AvatarStoring = AvatarService()
    var cameraAvailability: CameraAvailabilityProviding = DeviceCameraAvailability()
    var ruleEngine = RuleEngine()
}
