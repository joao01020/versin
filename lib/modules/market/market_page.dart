import 'package:flutter/material.dart';
import 'package:versin/app/locator.dart';
import 'package:versin/modules/dashboard/controllers/dashboard_controller.dart';

class MarketPage
    extends
        StatefulWidget {
  const MarketPage({
    super.key,
  });

  @override
  State<
    MarketPage
  >
  createState() => _MarketPageState();
}

class _MarketPageState
    extends
        State<
          MarketPage
        > {
  final DashboardController controller = sl();

  final List<
    String
  >
  _categories = [
    'Todos',
    'Trap',
    'R&B',
    'Drill',
    'Pluggnb',
    'Lyrics',
  ];

  int _selectedCategory = 0;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(
            20,
          ),
          child: TextField(
            style: const TextStyle(
              color: Colors.white,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withValues(
                alpha: 0.05,
              ),
              hintText: 'Buscar beats, letras ou produtores...',
              hintStyle: const TextStyle(
                color: Colors.white24,
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: Colors.white38,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  15,
                ),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
              ),
            ),
          ),
        ),

        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            itemCount: _categories.length,
            itemBuilder:
                (
                  _,
                  index,
                ) {
                  final selected =
                      _selectedCategory ==
                      index;

                  return GestureDetector(
                    onTap: () {
                      setState(
                        () {
                          _selectedCategory = index;
                        },
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 4,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? controller.accentNeon
                            : Colors.white.withValues(
                                alpha: 0.05,
                              ),
                        borderRadius: BorderRadius.circular(
                          20,
                        ),
                        border: Border.all(
                          color: selected
                              ? controller.accentNeon
                              : Colors.white10,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _categories[index],
                        style: TextStyle(
                          color: selected
                              ? Colors.black
                              : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
          ),
        ),

        const SizedBox(
          height: 20,
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(
              20,
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 240,
                height: 320,
                child: _buildMarketCard(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMarketCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.03,
        ),
        borderRadius: BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.05,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(
                    20,
                  ),
                ),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black,
                    controller.primaryPurple.withValues(
                      alpha: 0.5,
                    ),
                  ],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.play_circle_fill,
                    color: controller.accentNeon.withValues(
                      alpha: 0.8,
                    ),
                    size: 40,
                  ),

                  const Positioned(
                    top: 8,
                    right: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(
                          4,
                        ),
                        child: Icon(
                          Icons.favorite_border,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(
              12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hyper Light Beat',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                const Text(
                  'Prod. Astro',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'R\$ 197,00',
                      style: TextStyle(
                        color: controller.accentNeon,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const Icon(
                      Icons.add_shopping_cart,
                      color: Colors.white54,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
