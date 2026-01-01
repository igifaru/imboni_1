import 'package:flutter/material.dart';

class ProfessionalEmojiPicker extends StatefulWidget {
  final Function(String) onEmojiSelected;

  const ProfessionalEmojiPicker({super.key, required this.onEmojiSelected});

  @override
  State<ProfessionalEmojiPicker> createState() => _ProfessionalEmojiPickerState();
}

class _ProfessionalEmojiPickerState extends State<ProfessionalEmojiPicker> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  // Categorized Emojis (Subset for demonstration, expandable)
  final Map<String, List<String>> _emojiCategories = {
    'Recent': ['😂', '👍', '❤️', '😭', '🙏', '🔥', '🥰', '🤔', '🎉', '👏'],
    'Smileys': ['😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂', '🙂', '🙃', '😉', '😊', '😇', '🥰', '😍', '🤩', '😘', '😗', '😚', '😙', '😋', '😛', '😜', '🤪', '😝', '🤑', '🤗', '🤭', '🤫', '🤔', '🤐', '🤨', '😐', '😑', '😶', 'smirk', '😒', '🙄', '😬', 'lie', '😌', 'pensive', 'sleepy', 'drooling', 'sleeping', 'mask', 'fever', 'head_bandage', 'nauseated', 'vomiting', 'sneezing', 'hot', 'cold', 'woozy', 'dizzy', 'exploding', 'cowboy', 'party', 'sunglasses', 'nerd', 'monocle', 'confused', 'worried', 'slightly_frowning', 'frowning', 'open_mouth', 'hushed', 'astonished', 'flushed', 'pleading', 'frowning_open', 'anguished', 'fearful', 'cold_sweat', 'disappointed_relieved', 'cry', 'sob', 'scream', 'confounded', 'persevere', 'disappointed', 'sweat', 'weary', 'tired', 'yawn', 'triumph', 'rage', 'angry', 'cursing', 'smiling_imp', 'imp', 'skull', 'skull_crossbones', 'poop', 'clown', 'ogre', 'goblin', 'ghost', 'alien', 'space_invader', 'robot', 'jack_o_lantern', 'smiley_cat', 'smile_cat', 'joy_cat', 'heart_eyes_cat', 'smirk_cat', 'kissing_cat', 'scream_cat', 'crying_cat_face', 'pouting_cat', 'see_no_evil', 'hear_no_evil', 'speak_no_evil', 'wave', '🤚', 'fingers_crossed', 'vulcan', 'ok_hand', 'pinched_fingers', 'pinching_hand', 'v', 'love_you_gesture', 'metal', 'call_me_hand', 'point_left', 'point_right', 'point_up_2', 'middle_finger', 'point_down', 'point_up', '👍', '👎', 'shrug', 'fist', 'left_facing_fist', 'right_facing_fist', 'clap', 'raised_hands', 'open_hands', 'palms_up_together', 'handshake'],
    'Nature': ['🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯', '🦁', 'cow', 'pig', 'nose', 'frog', 'monkey_face', 'see_no_evil', 'hear_no_evil', 'speak_no_evil', 'monkey', 'chicken', 'penguin', 'bird', 'baby_chick', 'hatching_chick', 'hatched_chick', 'duck', 'eagle', 'owl', 'bat', 'wolf', 'boar', 'horse', 'unicorn', 'bee', 'bug', 'butterfly', 'snail', 'beetle', 'ant', 'mosquito', 'cricket', 'spider', 'web', 'turtle', 'snake', 'lizard', 'scorpion', 'crab', 'squid', 'octopus', 'shrimp', 'lobster', 'tropical_fish', 'fish', 'blowfish', 'dolphin', 'shark', 'whale', 'whale2', 'crocodile', 'leopard', 'zebra', 'gorilla', 'orangutan', 'elephant', 'hippopotamus', 'rhino', 'camel', 'dromedary_camel', 'giraffe', 'kangaroo', 'ox', 'water_buffalo', 'ram', 'sheep', 'llama', 'goat', 'deer', 'dog2', 'poodle', 'cat2', 'rooster', 'turkey', 'peacock', 'parrot', 'swan', 'flamingo', 'rabbit2', 'raccoon', 'badger', 'mouse2', 'rat', 'squirrel', 'hedgehog', 'sloth', 'otter', 'skunk', 'dragon', 'dragon_face', 'cactus', 'christmas_tree', 'evergreen_tree', 'deciduous_tree', 'palm_tree', 'seedling', 'herb', 'shamrock', 'four_leaf_clover', 'bamboo', 'tanabata_tree', 'leaves', 'fallen_leaf', 'maple_leaf', 'mushroom', 'shell', 'wheat', 'bouquet', 'tulip', 'rose', 'wilted_flower', 'hibiscus', 'cherry_blossom', 'blossom', 'sunflower', 'daisy', 'corn', 'ear_of_rice', 'grapes', 'melon', 'watermelon', 'tangerine', 'lemon', 'banana', 'pineapple', 'mango', 'apple', 'green_apple', 'pear', 'peach', 'cherries', 'strawberry', 'kiwifruit', 'tomato', 'coconut'],
    'Food': ['🥑', '🍆', '🥔', 'carrot', 'corn', 'hot_pepper', 'cucumber', 'leafy_green', 'broccoli', 'garlic', 'onion', 'mushroom', 'peanut', 'chestnut', 'bread', 'croissant', 'baguette_bread', 'pretzel', 'bagel', 'pancakes', 'waffle', 'cheese', 'meat_on_bone', 'poultry_leg', 'cut_of_meat', 'bacon', 'hamburger', 'fries', 'pizza', 'hotdog', 'sandwich', 'taco', 'burrito', 'stuffed_flatbread', 'falafel', 'egg', 'cooking', 'shallow_pan_of_food', 'stew', 'bowl_of_spoon', 'green_salad', 'popcorn', 'butter', 'salt', 'canned_food', 'bento', 'rice_cracker', 'rice_ball', 'rice', 'curry', 'ramen', 'spaghetti', 'sweet_potato', 'oden', 'sushi', 'fried_shrimp', 'fish_cake', 'moon_cake', 'dango', 'dumpling', 'fortune_cookie', 'takeout_box', 'crab', 'lobster', 'shrimp', 'squid', 'oyster', 'soft_serve', 'shaved_ice', 'ice_cream', 'doughnut', 'cookie', 'birthday', 'cake', 'cupcake', 'pie', 'chocolate_bar', 'candy', 'lollipop', 'custard', 'honey_pot', 'baby_bottle', 'milk_glass', 'coffee', 'tea', 'sake', 'champagne', 'wine_glass', 'cocktail', 'tropical_drink', 'beer', 'beers', 'clinking_glasses', 'cheers', 'tumbler_glass', 'cup_with_straw', 'beverage_box', 'mate', 'ice_cube', 'chopsticks', 'knife_fork_plate', 'fork_and_knife', 'spoon'],
    'Activities': ['⚽', '🏀', '🏈', '⚾', 'softball', 'tennis', 'volleyball', 'rugby_football', 'frisbee', 'ping_pong', 'badminton', 'goal_net', 'ice_hockey', 'field_hockey', 'lacrosse', 'cricket', 'golf', 'bow_and_arrow', 'fishing_pole_and_fish', 'boxing_glove', 'martial_arts_uniform', 'running_shirt_with_sash', 'skateboard', 'sled', 'ice_skate', 'curling_stone', 'ski', 'skier', 'snowboarder', 'person_lifting_weights', 'person_fencing', 'women_wrestling', 'men_wrestling', 'woman_cartwheeling', 'man_cartwheeling', 'basketball_man', 'basketball_woman', 'climbing', 'person_in_lotus_position', 'golfer', 'surfer', 'rowboat', 'swimmer', 'person_with_ball', 'horse_racing', 'trophy', 'running', 'medal', 'military_medal', '1st_place_medal', '2nd_place_medal', '3rd_place_medal', 'soccer', 'baseball', 'basketball', 'football', '8ball', 'bowling', 'dart', 'game_die', 'slot_machine', 'video_game', 'joystick', 'jigsaw', 'teddy_bear', 'spades', 'hearts', 'diamonds', 'clubs', 'chess_pawn', 'black_joker', 'mahjong', 'flower_playing_cards', 'performing_arts', 'frame_with_picture', 'art', 'thread', 'yarn'],
    'Objects': ['👓', '🕶', '🥽', '🥼', '🦺', '👔', '👕', '👖', '🧣', 'gloves', 'coat', 'socks', 'dress', 'kimono', 'sari', 'one_piece_swimsuit', 'briefs', 'shorts', 'bikini', 'woman_clothes', 'purse', 'handbag', 'pouch', 'shopping_bags', 'school_satchel', 'mans_shoe', 'athletic_shoe', 'hiking_boot', 'womans_flat_shoe', 'high_heel', 'sandal', 'ballet_shoes', 'boot', 'crown', 'womans_hat', 'tophat', 'mortar_board', 'billed_cap', 'helmet_with_white_cross', 'prayer_beads', 'lipstick', 'ring', 'gem', 'mute', 'speaker', 'sound', 'loud_sound', 'loudspeaker', 'mega', 'postal_horn', 'bell', 'no_bell', 'musical_score', 'musical_note', 'notes', 'studio_microphone', 'level_slider', 'control_knobs', 'microphone', 'headphones', 'radio', 'saxophone', 'accordion', 'guitar', 'musical_keyboard', 'trumpet', 'violin', 'banjo', 'drum', 'iphone', 'calling', 'phone', 'telephone_receiver', 'pager', 'fax', 'battery', 'electric_plug', 'computer', 'desktop_computer', 'printer', 'keyboard', 'computer_mouse', 'trackball', 'minidisc', 'floppy_disk', 'cd', 'dvd', 'abacus', 'movie_camera', 'film_frames', 'film_projector', 'tv', 'camera', 'camera_flash', 'video_camera', 'videocassette', 'mag', 'mag_right', 'candle', 'bulb', 'flashlight', 'izakaya_lantern', 'notebook_with_decorative_cover', 'closed_book', 'book', 'green_book', 'blue_book', 'orange_book', 'books', 'notebook', 'ledger', 'page_with_curl', 'scroll', 'page_facing_up', 'newspaper', 'bookmark_tabs', 'bookmark', 'label', 'moneybag', 'yen', 'dollar', 'euro', 'pound', 'money_with_wings', 'credit_card', 'receipt', 'chart', 'currency_exchange', 'heavy_dollar_sign', 'envelope', 'email', 'incoming_envelope', 'envelope_with_arrow', 'outbox_tray', 'inbox_tray', 'package', 'mailbox', 'mailbox_closed', 'mailbox_with_mail', 'mailbox_with_no_mail', 'postbox', 'ballot_box', 'pencil2', 'black_nib', 'fountain_pen', 'pen', 'paintbrush', 'crayon', 'memo', 'briefcase', 'file_folder', 'open_file_folder', 'card_index_dividers', 'date', 'calendar', 'spiral_note_pad', 'spiral_calendar', 'card_index', 'chart_with_upwards_trend', 'chart_with_downwards_trend', 'bar_chart', 'clipboard', 'pushpin', 'round_pushpin', 'paperclip', 'linked_paperclips', 'straight_ruler', 'triangular_ruler', 'scissors', 'card_file_box', 'file_cabinet', 'wastebasket', 'lock', 'unlock', 'lock_with_ink_pen', 'closed_lock_with_key', 'key', 'old_key', 'hammer', 'axe', 'pick', 'hammer_and_pick', 'hammer_and_wrench', 'dagger', 'crossed_swords', 'gun', 'boomerang', 'bow_and_arrow', 'shield', 'wrench', 'nut_and_bolt', 'gear', 'clamp', 'balance_scale', 'probing_cane', 'link', 'chains', 'toolbox', 'magnet', 'alembic', 'test_tube', 'petri_dish', 'dna', 'microscope', 'telescope', 'satellite', 'syringe', 'drop_of_blood', 'pill', 'adhesive_bandage', 'stethoscope', 'door', 'elevator', 'mirror', 'window', 'bed', 'couch_and_lamp', 'chair', 'toilet', 'plunger', 'shower', 'bathtub', 'mouse_trap', 'razor', 'lotion_bottle', 'safety_pin', 'broom', 'basket', 'roll_of_paper', 'soap', 'sponge', 'fire_extinguisher', 'shopping_cart', 'cigarette', 'coffin', 'funeral_urn', 'moyai', 'placard', 'identification_card'],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _emojiCategories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Container(
      width: 350,
      height: 400,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search emoji',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                ),
                prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey[400] : Colors.grey[600], size: 20),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
              ),
              onChanged: (value) {
                // To be implemented: filter emojis
                setState(() {}); 
              },
            ),
          ),
          
          // Category Tabs
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: EdgeInsets.zero,
            indicatorColor: isDark ? Colors.white : theme.primaryColor,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            labelPadding: const EdgeInsets.symmetric(horizontal: 12),
            tabs: const [
              Tab(icon: Icon(Icons.access_time, size: 20)), // Recent
              Tab(icon: Icon(Icons.emoji_emotions_outlined, size: 20)), // Smileys
              Tab(icon: Icon(Icons.pets, size: 20)), // Nature
              Tab(icon: Icon(Icons.fastfood, size: 20)), // Food
              Tab(icon: Icon(Icons.sports_soccer, size: 20)), // Activities
              Tab(icon: Icon(Icons.lightbulb_outline, size: 20)), // Objects
            ],
          ),
          
          const Divider(height: 1, thickness: 0.5),

          // Emoji Grid
          Expanded(
             child: TabBarView(
               controller: _tabController,
               children: _emojiCategories.keys.map((category) {
                 final emojis = _emojiCategories[category]!;
                 // Filter logic here if needed
                 
                 return GridView.builder(
                   padding: const EdgeInsets.all(8),
                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                     crossAxisCount: 8,
                     crossAxisSpacing: 4,
                     mainAxisSpacing: 4,
                   ),
                   itemCount: emojis.length,
                   itemBuilder: (context, index) {
                     final emoji = emojis[index];
                     // Only render if it looks like a valid emoji/icon string 
                     // (Simple workaround for long names in my dummy list)
                     if (emoji.length > 4) return const SizedBox.shrink(); 

                     return InkWell(
                       onTap: () => widget.onEmojiSelected(emoji),
                       borderRadius: BorderRadius.circular(4),
                       hoverColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                       child: Center(
                         child: Text(
                           emoji,
                           style: const TextStyle(fontSize: 22, color: Colors.white), // Force white if Noto font issue, else default
                         ),
                       ),
                     );
                   },
                 );
               }).toList(),
             ),
          ),
        ],
      ),
    );
  }
}
