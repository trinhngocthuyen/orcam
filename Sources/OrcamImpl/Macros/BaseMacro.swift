import SwiftSyntax
import SwiftSyntaxMacros
import MacroToolkit

public protocol BaseMacro: Macro {}
public protocol BaseMemberMacro: BaseMacro, MemberMacro {}
