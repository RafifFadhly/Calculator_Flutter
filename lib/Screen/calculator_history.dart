class CalculatorHistory {
  final int? id;
  final String expression;
  final String result;

  CalculatorHistory({this.id, required this.expression, required this.result});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'expression': expression,
      'result': result,
    };
  }

  @override
  String toString() {
    return 'CalculatorHistory{id: $id, expression: $expression, result: $result}';
  }
}
