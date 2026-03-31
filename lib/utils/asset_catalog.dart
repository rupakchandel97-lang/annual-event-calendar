import 'dart:convert';

import 'package:flutter/services.dart';

class AssetCatalog {
  static const List<String> _avatarAssets = [
    'img/Animation Characters/100/icons8-aang-100.png',
    'img/Animation Characters/100/icons8-amethyst-universe-100.png',
    'img/Animation Characters/100/icons8-badtz-maru-100.png',
    'img/Animation Characters/100/icons8-bill-cipher-100.png',
    'img/Animation Characters/100/icons8-brave-100.png',
    'img/Animation Characters/100/icons8-brutus-100.png',
    'img/Animation Characters/100/icons8-cheburashka-100.png',
    'img/Animation Characters/100/icons8-chip-100.png',
    'img/Animation Characters/100/icons8-dale-100.png',
    'img/Animation Characters/100/icons8-fairy-100.png',
    'img/Animation Characters/100/icons8-finding-nemo-100.png',
    'img/Animation Characters/100/icons8-genie-100.png',
    'img/Animation Characters/100/icons8-goofy-100.png',
    'img/Animation Characters/100/icons8-grim-adventures-of-billy-and-mandy-100.png',
    'img/Animation Characters/100/icons8-grinch-100.png',
    'img/Animation Characters/100/icons8-hello-kitty-100.png',
    'img/Animation Characters/100/icons8-hercules-100.png',
    'img/Animation Characters/100/icons8-jerry-100.png',
    'img/Animation Characters/100/icons8-jimmy-neutron-100.png',
    'img/Animation Characters/100/icons8-kermit-the-frog-100.png',
    'img/Animation Characters/100/icons8-keroppi-100.png',
    'img/Animation Characters/100/icons8-kiki-100.png',
    'img/Animation Characters/100/icons8-lala-100.png',
    'img/Animation Characters/100/icons8-launchpad-mcquack-100.png',
    'img/Animation Characters/100/icons8-louie-100.png',
    'img/Animation Characters/100/icons8-madagascar-100.png',
    'img/Animation Characters/100/icons8-mermaid-100.png',
    'img/Animation Characters/100/icons8-monsters,-inc---mike-100.png',
    'img/Animation Characters/100/icons8-monsters,-inc---sulley-100.png',
    'img/Animation Characters/100/icons8-morty-smith-100.png',
    'img/Animation Characters/100/icons8-my-melody-100.png',
    'img/Animation Characters/100/icons8-ninja-turtle-100.png',
    'img/Animation Characters/100/icons8-oggy-100.png',
    'img/Animation Characters/100/icons8-olive-oyl-100.png',
    'img/Animation Characters/100/icons8-peter-pan-100.png',
    'img/Animation Characters/100/icons8-pochacco-100.png',
    'img/Animation Characters/100/icons8-popeye-100.png',
    'img/Animation Characters/100/icons8-pumbaa-100.png',
    'img/Animation Characters/100/icons8-rick-sanchez-100.png',
    'img/Animation Characters/100/icons8-sailor-moon-folder-100.png',
    'img/Animation Characters/100/icons8-scooby-doo-100.png',
    'img/Animation Characters/100/icons8-scooby-doo-daphne-blake-100.png',
    'img/Animation Characters/100/icons8-scooby-doo-fred-jones-100.png',
    'img/Animation Characters/100/icons8-scooby-doo-shaggy-rogers-100.png',
    'img/Animation Characters/100/icons8-scooby-doo-velma-dinkley-100.png',
    'img/Animation Characters/100/icons8-scrooge-mcduck-100.png',
    'img/Animation Characters/100/icons8-shrek-100.png',
    'img/Animation Characters/100/icons8-simba-100.png',
    'img/Animation Characters/100/icons8-smurf-100.png',
    'img/Animation Characters/100/icons8-sokka-100.png',
    'img/Animation Characters/100/icons8-soul-100.png',
    'img/Animation Characters/100/icons8-spongebob-squarepants-100.png',
    'img/Animation Characters/100/icons8-stitch-character-100.png',
    'img/Animation Characters/100/icons8-the-coon-100.png',
    'img/Animation Characters/100/icons8-timon-100.png',
    'img/Animation Characters/100/icons8-tom-100.png',
    'img/Animation Characters/100/icons8-toph-100.png',
    'img/Animation Characters/100/icons8-totoro-100.png',
    'img/Animation Characters/100/icons8-wall-e-100.png',
    'img/Animation Characters/100/icons8-woody-woodpecker-100.png',
    'img/Animation Characters/100/icons8-zuko-100.png',
  ];

  static const List<String> _groceryAssets = [
    'img/_Grocery List/almond-butter.png',
    'img/_Grocery List/apple-fruit.png',
    'img/_Grocery List/apple-jam.png',
    'img/_Grocery List/apricot.png',
    'img/_Grocery List/artichoke.png',
    'img/_Grocery List/asparagus.png',
    'img/_Grocery List/avocado.png',
    'img/_Grocery List/bad-banana.png',
    'img/_Grocery List/baguette.png',
    'img/_Grocery List/banana.png',
    'img/_Grocery List/bao-bun.png',
    'img/_Grocery List/basil.png',
    'img/_Grocery List/beet.png',
    'img/_Grocery List/bitten-sandwich.png',
    'img/_Grocery List/black-berry.png',
    'img/_Grocery List/black-pepper.png',
    'img/_Grocery List/black-sesame-seeds.png',
    'img/_Grocery List/blueberry.png',
    'img/_Grocery List/bok-choy.png',
    'img/_Grocery List/bread-crumbs.png',
    'img/_Grocery List/bread.png',
    'img/_Grocery List/broccoli.png',
    'img/_Grocery List/broccolini.png',
    'img/_Grocery List/bulk-spices.png',
    'img/_Grocery List/butter.png',
    'img/_Grocery List/cabbage.png',
    'img/_Grocery List/carrot.png',
    'img/_Grocery List/cashew.png',
    'img/_Grocery List/cassis.png',
    'img/_Grocery List/cauliflower.png',
    'img/_Grocery List/celery.png',
    'img/_Grocery List/cereal.png',
    'img/_Grocery List/chard.png',
    'img/_Grocery List/cheese.png',
    'img/_Grocery List/cherry.png',
    'img/_Grocery List/chia-seeds.png',
    'img/_Grocery List/chili-pepper.png',
    'img/_Grocery List/chocolate-bar.png',
    'img/_Grocery List/cinnamon-sticks.png',
    'img/_Grocery List/citrus.png',
    'img/_Grocery List/clementine.png',
    'img/_Grocery List/cloves.png',
    'img/_Grocery List/cola.png',
    'img/_Grocery List/collard-greens.png',
    'img/_Grocery List/corn.png',
    'img/_Grocery List/cucumber.png',
    'img/_Grocery List/curry.png',
    'img/_Grocery List/dessert.png',
    'img/_Grocery List/dozen-eggs.png',
    'img/_Grocery List/dragon-fruit.png',
    'img/_Grocery List/egg-basket.png',
    'img/_Grocery List/egg-carton.png',
    'img/_Grocery List/egg.png',
    'img/_Grocery List/eggplant.png',
    'img/_Grocery List/eggs.png',
    'img/_Grocery List/falafel.png',
    'img/_Grocery List/finocchio.png',
    'img/_Grocery List/flax-seeds.png',
    'img/_Grocery List/flour-in-paper-packaging.png',
    'img/_Grocery List/french-fries.png',
    'img/_Grocery List/gailan.png',
    'img/_Grocery List/garlic.png',
    'img/_Grocery List/ginger.png',
    'img/_Grocery List/goyave.png',
    'img/_Grocery List/grains-of-rice.png',
    'img/_Grocery List/granulated-garlic.png',
    'img/_Grocery List/grapefruit.png',
    'img/_Grocery List/grapes.png',
    'img/_Grocery List/greek-salad.png',
    'img/_Grocery List/group-of-vegetables.png',
    'img/_Grocery List/half-orange.png',
    'img/_Grocery List/hamburger.png',
    'img/_Grocery List/hazelnut.png',
    'img/_Grocery List/honey-spoon.png',
    'img/_Grocery List/honey.png',
    'img/_Grocery List/hot-dog.png',
    'img/_Grocery List/ice-cream-cone.png',
    'img/_Grocery List/ice-cream-sundae.png',
    'img/_Grocery List/jackfruit.png',
    'img/_Grocery List/jam.png',
    'img/_Grocery List/kale.png',
    'img/_Grocery List/kawaii-french-fries.png',
    'img/_Grocery List/kawaii-ice-cream.png',
    'img/_Grocery List/kawaii-pizza.png',
    'img/_Grocery List/kawaii-soda.png',
    'img/_Grocery List/kiwi.png',
    'img/_Grocery List/kohlrabi.png',
    'img/_Grocery List/leek.png',
    'img/_Grocery List/lentil.png',
    'img/_Grocery List/lettuce.png',
    'img/_Grocery List/lime.png',
    'img/_Grocery List/list-view.png',
    'img/_Grocery List/lychee.png',
    'img/_Grocery List/mango.png',
    'img/_Grocery List/maple-syrup.png',
    'img/_Grocery List/matcha.png',
    'img/_Grocery List/mcdonald`s-french-fries.png',
    'img/_Grocery List/melon.png',
    'img/_Grocery List/milk-can.png',
    'img/_Grocery List/milk-carton.png',
    'img/_Grocery List/mint.png',
    'img/_Grocery List/mozzarella.png',
    'img/_Grocery List/mushroom.png',
    'img/_Grocery List/mustard.png',
    'img/_Grocery List/naan.png',
    'img/_Grocery List/nachos.png',
    'img/_Grocery List/noodles.png',
    'img/_Grocery List/No Image.png',
    'img/_Grocery List/nut.png',
    'img/_Grocery List/olive-oil-bottle.png',
    'img/_Grocery List/olive-oil.png',
    'img/_Grocery List/olive.png',
    'img/_Grocery List/onion.png',
    'img/_Grocery List/orange-juice.png',
    'img/_Grocery List/orange.png',
    'img/_Grocery List/papaya.png',
    'img/_Grocery List/paprika.png',
    'img/_Grocery List/parsnip.png',
    'img/_Grocery List/peach.png',
    'img/_Grocery List/peanut-butter.png',
    'img/_Grocery List/peanuts.png',
    'img/_Grocery List/pear.png',
    'img/_Grocery List/peas.png',
    'img/_Grocery List/pepitas.png',
    'img/_Grocery List/pickles.png',
    'img/_Grocery List/pineapple.png',
    'img/_Grocery List/pistachio-sauce.png',
    'img/_Grocery List/pizza.png',
    'img/_Grocery List/plantain.png',
    'img/_Grocery List/plum.png',
    'img/_Grocery List/pomegranate.png',
    'img/_Grocery List/popcorn.png',
    'img/_Grocery List/potato.png',
    'img/_Grocery List/pretzel.png',
    'img/_Grocery List/pumpkin.png',
    'img/_Grocery List/quinoa-seeds.png',
    'img/_Grocery List/radish.png',
    'img/_Grocery List/raisins.png',
    'img/_Grocery List/raspberry.png',
    'img/_Grocery List/refreshments.png',
    'img/_Grocery List/rice-vinegar.png',
    'img/_Grocery List/rolled-oats.png',
    'img/_Grocery List/salt-shaker.png',
    'img/_Grocery List/salt.png',
    'img/_Grocery List/sandwich.png',
    'img/_Grocery List/sauce-bottle.png',
    'img/_Grocery List/scallions.png',
    'img/_Grocery List/sesame-oil.png',
    'img/_Grocery List/sesame.png',
    'img/_Grocery List/smoked-paprika.png',
    'img/_Grocery List/soy-sauce.png',
    'img/_Grocery List/soy.png',
    'img/_Grocery List/spice.png',
    'img/_Grocery List/spinach.png',
    'img/_Grocery List/spirulina.png',
    'img/_Grocery List/spoon-of-sugar.png',
    'img/_Grocery List/squash.png',
    'img/_Grocery List/strawberry.png',
    'img/_Grocery List/sugar-cube.png',
    'img/_Grocery List/sugar-cubes.png',
    'img/_Grocery List/sugar.png',
    'img/_Grocery List/sunflower-butter.png',
    'img/_Grocery List/sunflower-oil.png',
    'img/_Grocery List/sweet-potato.png',
    'img/_Grocery List/sweetener.png',
    'img/_Grocery List/taco-salad.png',
    'img/_Grocery List/taco.png',
    'img/_Grocery List/tangerine.png',
    'img/_Grocery List/thyme.png',
    'img/_Grocery List/tomato.png',
    'img/_Grocery List/tomatoes.png',
    'img/_Grocery List/turmeric.png',
    'img/_Grocery List/vegetable-bouillion-paste.png',
    'img/_Grocery List/vegetables-bag.png',
    'img/_Grocery List/watermelon.png',
    'img/_Grocery List/white-beans.png',
    'img/_Grocery List/white-sesame-seeds.png',
    'img/_Grocery List/whole-apple.png',
    'img/_Grocery List/whole-watermelon.png',
    'img/_Grocery List/wrap.png',
    'img/_Grocery List/you-choy.png',
    'img/_Grocery List/zucchini.png',
  ];

  static const List<String> _profileImageAssets = [
    'img/_Profile Images/aang.png',
    'img/_Profile Images/amethyst-universe.png',
    'img/_Profile Images/avengers.png',
    'img/_Profile Images/badtz-maru.png',
    'img/_Profile Images/batman-logo.png',
    'img/_Profile Images/bill-cipher.png',
    'img/_Profile Images/brave.png',
    'img/_Profile Images/brutus.png',
    'img/_Profile Images/cheburashka.png',
    'img/_Profile Images/chip.png',
    'img/_Profile Images/dale.png',
    'img/_Profile Images/dare-devil.png',
    'img/_Profile Images/dexter.png',
    'img/_Profile Images/fairy.png',
    'img/_Profile Images/fantastic-four.png',
    'img/_Profile Images/finding-nemo.png',
    'img/_Profile Images/genie.png',
    'img/_Profile Images/goofy.png',
    'img/_Profile Images/green-arrow.png',
    'img/_Profile Images/green-lantern.png',
    'img/_Profile Images/grim-adventures-of-billy-and-mandy.png',
    'img/_Profile Images/grinch.png',
    'img/_Profile Images/harry-potter.png',
    'img/_Profile Images/hello-kitty.png',
    'img/_Profile Images/hercules.png',
    'img/_Profile Images/identity-disc.png',
    'img/_Profile Images/jerry.png',
    'img/_Profile Images/jimmy-neutron.png',
    'img/_Profile Images/kermit-the-frog.png',
    'img/_Profile Images/keroppi.png',
    'img/_Profile Images/kiki.png',
    'img/_Profile Images/lala.png',
    'img/_Profile Images/launchpad-mcquack.png',
    'img/_Profile Images/louie.png',
    'img/_Profile Images/madagascar.png',
    'img/_Profile Images/mermaid.png',
    'img/_Profile Images/millennium-rod.png',
    'img/_Profile Images/monsters,-inc---mike.png',
    'img/_Profile Images/monsters,-inc---sulley.png',
    'img/_Profile Images/morty-smith.png',
    'img/_Profile Images/my-melody.png',
    'img/_Profile Images/ninja-turtle.png',
    'img/_Profile Images/oggy.png',
    'img/_Profile Images/olive-oyl.png',
    'img/_Profile Images/one-ring.png',
    'img/_Profile Images/peter-pan.png',
    'img/_Profile Images/pixar-lamp-100 (2).png',
    'img/_Profile Images/pixar-lamp.png',
    'img/_Profile Images/pochacco.png',
    'img/_Profile Images/popeye.png',
    'img/_Profile Images/pumbaa.png',
    'img/_Profile Images/rick-sanchez.png',
    'img/_Profile Images/roll-no-21.png',
    'img/_Profile Images/sailor-moon-folder.png',
    'img/_Profile Images/scooby-doo-daphne-blake.png',
    'img/_Profile Images/scooby-doo-fred-jones.png',
    'img/_Profile Images/scooby-doo-shaggy-rogers.png',
    'img/_Profile Images/scooby-doo-velma-dinkley.png',
    'img/_Profile Images/scooby-doo.png',
    'img/_Profile Images/scrooge-mcduck.png',
    'img/_Profile Images/shrek.png',
    'img/_Profile Images/simba.png',
    'img/_Profile Images/smurf.png',
    'img/_Profile Images/sokka.png',
    'img/_Profile Images/sons-of-anarchy.png',
    'img/_Profile Images/soul.png',
    'img/_Profile Images/spider-man-new.png',
    'img/_Profile Images/spider-man-old.png',
    'img/_Profile Images/spongebob-squarepants.png',
    'img/_Profile Images/stitch-character.png',
    'img/_Profile Images/superman.png',
    'img/_Profile Images/the-big-bang-theory.png',
    'img/_Profile Images/the-coon.png',
    'img/_Profile Images/the-flash-sign.png',
    'img/_Profile Images/timon.png',
    'img/_Profile Images/tom.png',
    'img/_Profile Images/toph.png',
    'img/_Profile Images/totoro.png',
    'img/_Profile Images/wall-e.png',
    'img/_Profile Images/woody-woodpecker.png',
    'img/_Profile Images/x-men.png',
    'img/_Profile Images/zuko.png',
  ];

  static List<String>? _manifestAssets;

  static Future<List<String>> listAssets(String prefix) async {
    if (prefix == 'img/Animation Characters/100/') {
      return _avatarAssets;
    }
    if (prefix == 'img/_Grocery List/') {
      return _groceryAssets;
    }
    if (prefix == 'img/_Profile Images/') {
      return _profileImageAssets;
    }
    if (prefix == 'img/_Movies to Watch/') {
      final manifestAssets = await _loadManifestAssets();
      return manifestAssets.where((asset) => asset.startsWith(prefix)).toList()
        ..sort();
    }

    final manifestAssets = await _loadManifestAssets();
    final matching = manifestAssets
        .where((asset) => asset.startsWith(prefix))
        .toList()
      ..sort();
    if (matching.isNotEmpty) {
      return matching;
    }

    return const [];
  }

  static Future<List<String>> _loadManifestAssets() async {
    if (_manifestAssets != null) {
      return _manifestAssets!;
    }

    try {
      final manifest = await rootBundle.loadString('AssetManifest.json');
      final decoded = json.decode(manifest) as Map<String, dynamic>;
      _manifestAssets = decoded.keys.toList(growable: false);
    } catch (_) {
      _manifestAssets = const <String>[];
    }
    return _manifestAssets!;
  }

  static String labelFromAssetPath(String path) {
    final fileName = path.split('/').last;
    final withoutExtension = fileName.replaceFirst(RegExp(r'\.[^.]+$'), '');
    return withoutExtension
        .replaceAll('icons8-', '')
        .replaceAll('-100', '')
        .replaceAll('`', '')
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .replaceAllMapped(
          RegExp(r'\b\w'),
          (match) => match.group(0)!.toUpperCase(),
        )
        .trim();
  }

  static String normalizedLookup(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
