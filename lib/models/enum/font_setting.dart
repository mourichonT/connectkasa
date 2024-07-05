enum SizeFont {
  header(25),
  h1(20),
  h2(18),
  h3(16),
  para(14);

  final double size;

  const SizeFont(this.size);
}



//La taille de la police header est ${SizeFont.header.size}