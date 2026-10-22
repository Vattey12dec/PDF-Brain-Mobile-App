import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

/// Converts \( ... \) and \[ ... \] (another common Gemini style) to $ and $$.
String _normalizeMath(String text) {
  return text
      .replaceAllMapped(
        RegExp(r'\\\[(.+?)\\\]', dotAll: true),
        (m) => '\$\$${m[1]}\$\$',
      )
      .replaceAllMapped(
        RegExp(r'\\\((.+?)\\\)', dotAll: true),
        (m) => '\$${m[1]}\$',
      );
}

/// Matches $$ ... $$ (display) and $ ... $ (inline).
class _LatexSyntax extends md.InlineSyntax {
  _LatexSyntax() : super(r'\$\$([\s\S]+?)\$\$|\$([^\$\n]+?)\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final isDisplay = match[1] != null;
    final tex = (match[1] ?? match[2] ?? '').trim();
    final el = md.Element.text('latex', tex);
    el.attributes['display'] = isDisplay.toString();
    parser.addNode(el);
    return true;
  }
}

class _LatexBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final tex = element.textContent;
    final isDisplay = element.attributes['display'] == 'true';
    final base = preferredStyle?.fontSize ?? 15;
    final color =
        preferredStyle?.color ?? Theme.of(context).colorScheme.onSurface;

    final math = Math.tex(
      tex,
      textStyle: TextStyle(
        fontSize: isDisplay ? base * 1.15 : base,
        color: color,
      ),
      onErrorFallback: (err) => Text(tex, style: TextStyle(color: color)),
    );

    if (!isDisplay) return math;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: math,
      ),
    );
  }
}

/// Drop-in replacement for MarkdownBody that also renders LaTeX math.
class MathMarkdown extends StatelessWidget {
  final String data;
  final bool selectable;

  const MathMarkdown({super.key, required this.data, this.selectable = true});

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: _normalizeMath(data),
      selectable: selectable,
      builders: {'latex': _LatexBuilder()},
      extensionSet: md.ExtensionSet(
        md.ExtensionSet.gitHubFlavored.blockSyntaxes,
        [_LatexSyntax(), ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes],
      ),
    );
  }
}