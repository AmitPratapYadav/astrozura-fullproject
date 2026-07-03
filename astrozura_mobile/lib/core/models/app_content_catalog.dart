enum HomeBannerDestination { shop, pooja, horoscope }

class HomeBannerItem {
  final String assetPath;
  final HomeBannerDestination destination;

  const HomeBannerItem({
    required this.assetPath,
    required this.destination,
  });
}

const homeBanners = <HomeBannerItem>[
  HomeBannerItem(
    assetPath: 'assets/images/banners/shop.png',
    destination: HomeBannerDestination.shop,
  ),
  HomeBannerItem(
    assetPath: 'assets/images/banners/pooja.png',
    destination: HomeBannerDestination.pooja,
  ),
  HomeBannerItem(
    assetPath: 'assets/images/banners/horoscope.png',
    destination: HomeBannerDestination.horoscope,
  ),
];

class ZodiacSignInfo {
  final String key;
  final String name;
  final String vedicName;
  final String assetPath;

  const ZodiacSignInfo({
    required this.key,
    required this.name,
    required this.vedicName,
    required this.assetPath,
  });
}

const zodiacSigns = <ZodiacSignInfo>[
  ZodiacSignInfo(
    key: 'aries',
    name: 'Aries',
    vedicName: 'Mesha',
    assetPath: 'assets/images/zodiac/Aries.png',
  ),
  ZodiacSignInfo(
    key: 'taurus',
    name: 'Taurus',
    vedicName: 'Vrishabha',
    assetPath: 'assets/images/zodiac/Taurus.png',
  ),
  ZodiacSignInfo(
    key: 'gemini',
    name: 'Gemini',
    vedicName: 'Mithuna',
    assetPath: 'assets/images/zodiac/Gemini.png',
  ),
  ZodiacSignInfo(
    key: 'cancer',
    name: 'Cancer',
    vedicName: 'Karka',
    assetPath: 'assets/images/zodiac/Cancer.png',
  ),
  ZodiacSignInfo(
    key: 'leo',
    name: 'Leo',
    vedicName: 'Simha',
    assetPath: 'assets/images/zodiac/Leo.png',
  ),
  ZodiacSignInfo(
    key: 'virgo',
    name: 'Virgo',
    vedicName: 'Kanya',
    assetPath: 'assets/images/zodiac/Virgo.png',
  ),
  ZodiacSignInfo(
    key: 'libra',
    name: 'Libra',
    vedicName: 'Tula',
    assetPath: 'assets/images/zodiac/Libra.png',
  ),
  ZodiacSignInfo(
    key: 'scorpio',
    name: 'Scorpio',
    vedicName: 'Vrischika',
    assetPath: 'assets/images/zodiac/Scorpio.png',
  ),
  ZodiacSignInfo(
    key: 'sagittarius',
    name: 'Sagittarius',
    vedicName: 'Dhanu',
    assetPath: 'assets/images/zodiac/Sagittarius.png',
  ),
  ZodiacSignInfo(
    key: 'capricorn',
    name: 'Capricorn',
    vedicName: 'Makara',
    assetPath: 'assets/images/zodiac/Capricorn.png',
  ),
  ZodiacSignInfo(
    key: 'aquarius',
    name: 'Aquarius',
    vedicName: 'Kumbha',
    assetPath: 'assets/images/zodiac/Aquarius.png',
  ),
  ZodiacSignInfo(
    key: 'pisces',
    name: 'Pisces',
    vedicName: 'Meena',
    assetPath: 'assets/images/zodiac/Pisces.png',
  ),
];
