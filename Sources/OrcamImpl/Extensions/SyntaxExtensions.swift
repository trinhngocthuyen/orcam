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
    modifiers.compactMap(\.name.tokenKind.keyword)
  }

  var accessLevel: String? {
    let kws = keywords
    if kws.contains(.open) { return "open" }
    if kws.contains(.public) { return "public" }
    if kws.contains(.internal) { return "internal" }
    if kws.contains(.private) { return "private" }
    if kws.contains(.fileprivate) { return "fileprivate" }
    return nil
  }
}

public extension WithModifiersSyntax {
  private var _proxy: WithModifiersSyntaxProxy { .init(self) }
  var keywords: [Keyword] { _proxy.keywords }
  var accessLevel: String? { _proxy.accessLevel }

  func withAccessLevel(_ accessLevel: String?) -> Self {
    guard let accessLevel else { return self }
    return with(
      \.modifiers,
      modifiers + [DeclModifierSyntax(name: "\(raw: accessLevel)")]
    )
  }
}

public extension DeclGroupSyntax {
  private var _proxy: WithModifiersSyntaxProxy { .init(self) }
  var keywords: [Keyword] { _proxy.keywords }
  var accessLevel: String? { _proxy.accessLevel }

  var entityName: TokenSyntax? {
    self.as(ClassDeclSyntax.self)?.name ??
      self.as(StructDeclSyntax.self)?.name ??
      self.as(EnumDeclSyntax.self)?.name
  }
}

public extension InitializerDeclSyntax {
  func withParameters(
    _ parameters: some Sequence<FunctionParameter>
  ) -> Self {
    with(
      \.signature,
      signature
        .with(
          \.parameterClause,
          FunctionParameterClauseSyntax(parameters: parameters.asParameterList)
        )
    )
  }
}

public extension TokenKind {
  var keyword: Keyword? {
    switch self {
    case let .keyword(keyword): return keyword
    default: return nil
    }
  }
}

// MARK: swift-macro-toolkit's types

public extension DeclGroup {
  var variables: [Variable] { members.compactMap(\.asVariable) }
  var accessLevel: String? { _syntax.accessLevel }

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

  var isPropertyWrapper: Bool {
    !attributes.compactMap(\.attribute).isEmpty
  }
}

public extension VariableBinding {
  var asFunctionParameter: FunctionParameter? {
    zip(self.identifier, self.type).map { FunctionParameter(name: $0.0, type: $0.1) }
  }
}

public extension FunctionParameter {
  var withEscapingAttribute: Self {
    guard let type = type.asFunctionType else { return self }
    return FunctionParameter(
      label: label,
      name: name,
      type: "@escaping \(raw: type.description)"
    )
  }

  var withDefaultValueForOptional: Self {
    guard type.isOptional else { return self }
    var copy = self
    copy._syntax.defaultValue = InitializerClauseSyntax(value: NilLiteralExprSyntax())
    return copy
  }

  func withoutTrivia() -> Self {
    FunctionParameter(_syntax.withoutTrivia())
  }
}
