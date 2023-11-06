import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct InitMacro: MemberMacro {
  enum CustomError: Error {
    case message(String)
  }

  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard declaration.is(StructDeclSyntax.self) || declaration.is(ClassDeclSyntax.self) else {
      throw CustomError.message("Not a struct or class")
    }

    var headerArgs = [String](), bodyArgs = [String]()
    for property in declaration.storedProperties() {
      if let patternBinding = property.bindings.first?.as(PatternBindingSyntax.self),
         let identitifer = patternBinding.pattern.as(IdentifierPatternSyntax.self)?.identifier,
         let type = patternBinding.typeAnnotation?.type
      {
        let name = identitifer
        let typeDescription = type.trimmedDescription
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
