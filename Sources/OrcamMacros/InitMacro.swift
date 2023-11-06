import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct InitMacro: MemberMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard declaration.is(StructDeclSyntax.self) || declaration.is(ClassDeclSyntax.self) else {
      throw CustomError.message("Not a struct or class")
    }

    let defaultForOptional = try node.getArgument(name: "defaultForOptional", default: true)

    var headerArgs = [String](), bodyArgs = [String]()
    for property in declaration.storedProperties() where !property.isConstant {
      if let patternBinding = property.bindings.first?.as(PatternBindingSyntax.self),
         let identitifer = patternBinding.pattern.as(IdentifierPatternSyntax.self)?.identifier,
         let type = patternBinding.typeAnnotation?.type
      {
        let name = identitifer
        var typeDescription = type.trimmedDescription
        // If it's a closure, add @escaping
        if type.is(FunctionTypeSyntax.self) {
          typeDescription = "@escaping \(typeDescription)"
        }
        if defaultForOptional && (typeDescription.contains("?") || typeDescription.contains("Optional<")) {
           typeDescription  += " = nil"
        }
        headerArgs.append("\(name): \(typeDescription)")
        bodyArgs.append("self.\(name) = \(name)")
      }
    }

    let header = SyntaxNodeString(
      format: "%@(\n%@\n)",
      declaration.isPublic() ? "public init" : "init",
      headerArgs.joined(separator: ",\n")
    )
    let initDeclSyntax = try InitializerDeclSyntax(header) {
      for arg in bodyArgs {
        ExprSyntax(stringLiteral: arg)
      }
    }
    return [DeclSyntax(initDeclSyntax)]
  }
}
