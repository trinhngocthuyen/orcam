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

    func createCopyFuncDeclSyntax(
      paramaters: [FunctionParameter],
      parametersCall: [String],
      extraBody: ExprSyntax? = nil
    ) throws -> DeclSyntax {
      let parametersCallStr = parametersCall.joined(separator: ", ")
      return try FunctionDeclSyntax("func copy() -> Self") {
        if let extraBody {
          "\(raw: extraBody)"
        }
        "return .init(\(raw: parametersCallStr))"
      }
      .withParameters(paramaters)
      .withAccessLevel(accessLevel)
      .asDeclSyntax
    }

    var syntaxes: [DeclSyntax] = []
    try syntaxes.append(
      createCopyFuncDeclSyntax(
        paramaters: initializerParameters.map { parameter in
          FunctionParameter(
            name: parameter.name,
            type: "\(raw: parameter.type.description)?"
          ).withDefaultValueForOptional
        },
        parametersCall: initializerParameters.map { parameter in
          "\(parameter.name): \(parameter.name) ?? self.\(parameter.name)"
        }
      )
    )

    if arguments.value(for: "closure", default: false) {
      try syntaxes.append(
        createCopyFuncDeclSyntax(
          paramaters: initializerParameters.map { parameter in
            FunctionParameter(
              name: "update_\(parameter.name)",
              type: "((\(raw: parameter.type.description)) -> \(raw: parameter.type.description))?"
            ).withDefaultValueForOptional
          },
          parametersCall: initializerParameters.map { parameter in
            "\(parameter.name): call(update_\(parameter.name), self.\(parameter.name))"
          },
          extraBody: "func call<V>(_ f: ((V) -> V)?, _ v: V) -> V { f?(v) ?? v }"
        )
      )
    }

    return syntaxes
  }
}
