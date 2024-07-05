class AddressDecode {
  List<int> getAddressNumber(String address) {
    RegExp regExp = RegExp(r'\d+');
    Iterable<Match> matches = regExp.allMatches(address);

    List<int> integers = [];

    for (Match match in matches) {
      integers.add(int.parse(match.group(0)!));
      print(integers);
    }
    return integers;
  }
}
