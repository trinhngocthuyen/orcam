import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import MacroToolkit

public struct CopyableMacro: BaseMemberMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    try declaration.expectKind(.classDecl, .structDecl)
    let arguments = try MacroArguments(from: node.asMacroAttribute)
    let accessLevel = arguments.value(for: "accessLevel", default: declaration.accessLevel)

    let initializerParameters = InitMacroHelper.initializerParameters(of: declaration)
    let copyFuncParameters = initializerParameters
      .map { parameter in
        FunctionParameter(
          name: "update_\(parameter.name)",
          type: "((\(raw: parameter.type.description)) -> \(raw: parameter.type.description))?"
        ).withDefaultValueForOptional
      }
    let initializerParametersCall = initializerParameters.map { parameter in
      "\(parameter.name): call(update_\(parameter.name), self.\(parameter.name))"
    }.joined(separator: ", ")

    let copyFuncDeclSyntax = try FunctionDeclSyntax("func copy() -> Self") {
      "func call<V>(_ f: ((V) -> V)?, _ v: V) -> V { f?(v) ?? v }"
      "return .init(\(raw: initializerParametersCall))"
    }
    .withParameters(copyFuncParameters)
    .withAccessLevel(accessLevel)
    return [
      copyFuncDeclSyntax.asDeclSyntax,
    ]
  }
}
