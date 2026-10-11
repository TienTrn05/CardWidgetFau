class BrandCarFontOption {
  const BrandCarFontOption({required this.name, this.fontFamily});

  final String name;
  final String? fontFamily;
}

const brandCarFontOptions = <BrandCarFontOption>[
  BrandCarFontOption(name: 'Default'),
  BrandCarFontOption(name: 'Be Vietnam Pro', fontFamily: 'Helvetica Neue'),
  BrandCarFontOption(name: 'DM Serif', fontFamily: 'Georgia'),
  BrandCarFontOption(name: 'Domine', fontFamily: 'Palatino'),
];
