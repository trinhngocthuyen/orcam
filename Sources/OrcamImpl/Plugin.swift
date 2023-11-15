import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct OrcamPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    InitMacro.self,
    SingletonMacro.self,
  ]
}
