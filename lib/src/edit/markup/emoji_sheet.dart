import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';

/// the popular emojis, a tap gives back the one picked.
class EmojiSheet extends StatelessWidget {
  final ScrollController? scroll;

  const EmojiSheet({this.scroll, super.key});

  static Future<String?> show(BuildContext context) {
    final scope = PickerScope.of(context);
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: scope.theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(PickerLayout.radius * 2)),
      ),
      // the pinned notch paints its own background, it would square the corners off
      clipBehavior: Clip.antiAlias,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.25,
        maxChildSize: 1,
        builder: (context, scroll) => scope.wrap(EmojiSheet(scroll: scroll)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    return SafeArea(
      top: false,
      child: CustomScrollView(
        controller: scroll,
        slivers: [
          // inside the scroll view, so dragging it slides the sheet up as well as down
          PinnedHeaderSliver(
            child: ColoredBox(
              color: scope.theme.surface,
              child: Center(
                child: Container(
                  width: 32,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: PickerLayout.padding / 2),
                  decoration: BoxDecoration(
                    color: scope.theme.onSurfaceMuted,
                    borderRadius: const BorderRadius.all(Radius.circular(2)),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(PickerLayout.padding),
            sliver: SliverGrid.builder(
              itemCount: emojis.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 52),
              itemBuilder: (context, index) => InkWell(
                onTap: () => Navigator.of(context).pop(emojis[index]),
                child: Center(child: Text(emojis[index], style: const TextStyle(fontSize: 30))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// the popular ones, grouped like a phone keyboard.
  static final List<String> emojis =
      """
😀 😃 😄 😁 😆 😅 🤣 😂 🙂 🙃 😉 😊 😇 🥰 😍 🤩
😘 😗 😚 😙 🥲 😋 😛 😜 🤪 😝 🤑 🤗 🤭 🤫 🤔 🤐
🤨 😐 😑 😶 😏 😒 🙄 😬 😌 😔 😪 🤤 😴 😷 🤒 🤕
🤢 🤮 🤧 🥵 🥶 🥴 😵 🤯 🤠 🥳 😎 🤓 🧐 😕 😟 🙁
😮 😯 😲 😳 🥺 😦 😧 😨 😰 😥 😢 😭 😱 😖 😣 😞
😓 😩 😫 🥱 😤 😡 😠 🤬 😈 👿 💀 💩 🤡 👻 👽 🤖
😺 😸 😹 😻 😼 😽 🙀 😿 😾 🙈 🙉 🙊 👋 🤚 ✋ 🖖
👌 🤌 🤏 ✌️ 🤞 🤟 🤘 🤙 👈 👉 👆 👇 ☝️ 👍 👎 ✊
👊 🤛 🤜 👏 🙌 👐 🤲 🤝 🙏 ✍️ 💅 💪 👀 👁️ 👄 💋
👶 👦 👧 👨 👩 👴 👵 🙋 🙅 🙆 🤦 🤷 💃 🕺 👑 🎩
🕶️ 👓 ❤️ 🧡 💛 💚 💙 💜 🖤 🤍 🤎 💔 ❣️ 💕 💞 💓
💗 💖 💘 💝 💯 💢 💥 💫 💦 💨 💬 💭 💤 ✨ ⭐ 🌟
⚡ 🔥 ✅ ❌ ❗ ❓ ⚠️ 🚫 ♻️ ➕ ➖ ➡️ ⬅️ ⬆️ ⬇️ 🔴
🟢 🔵 🐶 🐱 🐭 🐹 🐰 🦊 🐻 🐼 🐨 🐯 🦁 🐮 🐷 🐸
🐵 🐔 🐧 🐦 🐤 🦆 🦅 🦉 🦄 🐝 🦋 🐌 🐞 🐢 🐍 🐙
🐠 🐬 🐳 🦈 🐊 🐘 🦒 🐎 🐑 🐪 🌵 🌲 🌴 🌱 🍀 🍁
🍂 🌷 🌹 🌺 🌸 🌼 🌻 🌞 🌝 🌛 🌙 🌎 🪐 ☀️ 🌤️ ☁️
🌧️ ⛈️ ❄️ ☃️ 🌊 💧 🍏 🍎 🍐 🍊 🍋 🍌 🍉 🍇 🍓
🫐 🍒 🍑 🥭 🍍 🥥 🥝 🍅 🥑 🥦 🌽 🥕 🌶️ 🥐 🍞 🧀
🥚 🍳 🥞 🥓 🍗 🍔 🍟 🍕 🌭 🥪 🌮 🌯 🥗 🍝 🍜 🍣
🍤 🍦 🍩 🍪 🎂 🍰 🧁 🍫 🍬 🍭 🍿 ☕ 🍵 🥤 🧃 🍺
🥂 ⚽ 🏀 🏈 ⚾ 🎾 🏐 🎱 🏓 🏸 🥊 🏆 🥇 🎯 🎮 🎲
🧩 🎨 🎬 🎤 🎧 🎵 🎶 🎸 🎹 🥁 🎉 🎊 🎈 🎁 🎀 🪄
🧸 🚗 🚕 🚌 🏎️ 🚲 🛵 ✈️ 🚀 🛸 🚢 ⛵ 🏠 🏖️ 🏝️ ⛰️
🗽 🗼 🎡 📱 💻 ⌚ 📷 📸 🎥 💡 🔑 💰 💎 📌 📍 ✏️
📚 ⏰ 🕯️ 🛒 🧳 ☂️ 🌂 🏁 🚩 🏳️ 🏴
"""
          .trim()
          .split(RegExp(r"\s+"));
}
