/// Style d'affichage personnalisé d'un post (fonctionnalité "demande aux
/// voisins" : fond coloré/image + police personnalisés). Regroupe les 6
/// champs auparavant séparés sur Post (backgroundColor, backgroundImage,
/// fontSize, fontWeight, fontColor, fontStyle).
class PostStyle {
  final String? backgroundColor;
  final String? backgroundImage;
  final double? fontSize;
  final String? fontWeight;
  final String? fontColor;
  final String? fontStyle;

  PostStyle({
    this.backgroundColor,
    this.backgroundImage,
    this.fontSize,
    this.fontWeight,
    this.fontColor,
    this.fontStyle,
  });

  factory PostStyle.fromMap(Map<String, dynamic> map) {
    return PostStyle(
      backgroundColor: map['backgroundColor'],
      backgroundImage: map['backgroundImage'],
      fontSize: (map['fontSize'] as num?)?.toDouble(),
      fontWeight: map['fontWeight'],
      fontColor: map['fontColor'],
      fontStyle: map['fontStyle'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'backgroundColor': backgroundColor,
      'backgroundImage': backgroundImage,
      'fontSize': fontSize,
      'fontWeight': fontWeight,
      'fontColor': fontColor,
      'fontStyle': fontStyle,
    };
  }
}
