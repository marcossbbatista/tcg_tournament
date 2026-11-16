/// Interpreta texto exportado pelo Pokémon TCG Live ou Limitless.
class CartaDeck {
  final int quantidade;
  final String nome;
  final String? colecao;
  final String? numero;
  final String categoria;
  const CartaDeck(this.quantidade, this.nome, this.colecao, this.numero, this.categoria);
}

class DecklistParser {
  static List<CartaDeck> interpretar(String texto) {
    final cartas = <CartaDeck>[];
    var categoria = 'Outro';
    for (final raw in texto.split(RegExp(r'\r?\n'))) {
      final linha = raw.trim();
      if (linha.isEmpty || linha.startsWith('##')) continue;
      if (RegExp(r'^(Pok[eé]mon|Trainer|Treinador|Energy|Energia)\s*:', caseSensitive: false).hasMatch(linha)) {
        categoria = linha.split(':').first.trim();
        continue;
      }
      if (RegExp(r'^(Total Cards|Total de Cartas)\s*:', caseSensitive: false).hasMatch(linha)) continue;
      final m = RegExp(r'^(\d+)\s+(.+?)(?:\s+([A-Z0-9]{2,12})\s+(\d+[a-zA-Z]?))?$').firstMatch(linha);
      if (m == null) throw FormatException('Linha inválida: $linha');
      final n = int.parse(m.group(1)!);
      if (n < 1 || n > 60) throw FormatException('Quantidade inválida: $linha');
      final nome = m.group(2)!.trim();
      if (nome.isEmpty) throw FormatException('Carta sem nome: $linha');
      cartas.add(CartaDeck(n, nome, m.group(3), m.group(4), categoria));
    }
    final total = cartas.fold<int>(0, (s, carta) => s + carta.quantidade);
    if (total != 60) throw FormatException('A decklist deve ter 60 cartas; foram encontradas $total.');
    return cartas;
  }
}
