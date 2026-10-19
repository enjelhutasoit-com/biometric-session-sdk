import Testing

@testable import BiometricSessionCore

@Suite("Bootstrap")
struct CoreModuleTests {
    @Test("Core module links and is reachable from tests")
    func moduleNameIsStable() {
        #expect(CoreModule.name == "BiometricSessionCore")
    }
}
