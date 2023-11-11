import SwiftSyntax
import SwiftSyntaxBuilder
import MacroToolkit

// MARK: swift-syntax's types
public extension SyntaxProtocol {
  func expectKind(_ kinds: SyntaxKind...) throws {
    guard kinds.contains(kind) else {
      throw MacroError("Expect declaration kind to be one of: \(kinds). Actual: \(kind)")
    }
  }
}

public extension AttributeSyntax {
  var asMacroAttribute: MacroAttribute {
    get throws {
      if let attribute = Attribute(self).asMacroAttribute {
        return attribute
      }
      throw MacroError("Cannot cast \(self) to MacroAttribute")
    }
  }
}

public extension DeclSyntaxProtocol {
  var asDeclSyntax: DeclSyntax {
    DeclSyntax(self)
  }
}


// NOTE: This struct is a proxy to unify the modifiers syntax.
// Apple declares both `WithModifiersSyntax` and `DeclGroupSyntax` having the same `modifiers` property.
// However, the two protocols have no relation at all.
// This results in duplications when writing extensions with `modifiers`.
private struct WithModifiersSyntaxProxy {
  private var modifiers: DeclModifierListSyntax

  init(_ proxy: WithModifiersSyntax) {
    self.modifiers = proxy.modifiers
  }

  init(_ proxy: DeclGroupSyntax) {
    self.modifiers = proxy.modifiers
  }

  var keywords: [Keyword] {
    modifiers.compactMap { $0.name.tokenKind.keyword }
  }

  var accessLevel: String? {
    let kws = keywords
    if kws.contains(.open) { return "open" }
    if kws.contains(.public) { return "public" }
    if kws.contains(.private) { return "private" }
    if kws.contains(.fileprivate) { return "fileprivate" }
    return nil
  }
}

public extension WithModifiersSyntax {
  private var _proxy: WithModifiersSyntaxProxy { .init(self) }
  var keywords: [Keyword] { _proxy.keywords }
  var accessLevel: String? {  _proxy.accessLevel }
}

public extension DeclGroupSyntax {
  private var _proxy: WithModifiersSyntaxProxy { .init(self) }
  var keywords: [Keyword] { _proxy.keywords }
  var accessLevel: String? {  _proxy.accessLevel }

  var entityName: TokenSyntax? {
    self.as(ClassDeclSyntax.self)?.name ??
    self.as(StructDeclSyntax.self)?.name ??
    self.as(EnumDeclSyntax.self)?.name
  }
}

public extension InitializerDeclSyntax {
  init(
    accessLevel: String? = nil,
    literals: [(header: String, body: String)]
  ) throws {
    let header = SyntaxNodeString(
      stringLiteral: String(
        format: "%@(\n%@\n)",
        [accessLevel, "init"].compactMap { $0 }.joined(separator: " "),
        literals.map { $0.header }.joined(separator: ",\n")
      )
    )
    try self.init(header) {
      for literal in literals {
        ExprSyntax(stringLiteral: literal.body)
      }
    }
  }
}

public extension TokenKind {
  var keyword: Keyword? {
    switch self {
    case .keyword(let keyword): return keyword
    default: return nil
    }
  }
}


// MARK: swift-macro-toolkit's types
public extension DeclGroup {
  var variables: [Variable] { members.compactMap { $0.asVariable } }
  var accessLevel: String? {  _syntax.accessLevel }

  func containsVariable(name: String) -> Bool {
    variables.contains { $0.identifiers.contains(name) }
  }
}

public extension Type {
  var isOptional: Bool {
    description.hasPrefix("Optional<") || description.hasSuffix("?")
  }
}

public extension Variable {
  var isLet: Bool { _syntax.bindingSpecifier.tokenKind.keyword == .let }
  var isInitialized: Bool { bindings.contains { $0.initialValue != nil } }
  var isConstant: Bool { isLet && isInitialized }
}
