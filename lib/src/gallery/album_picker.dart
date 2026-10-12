import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/gallery/gallery_controller.dart';
import 'package:image_picker_plus/src/models/album.dart';
import 'package:image_picker_plus/src/widgets/picker_popup.dart';

class AlbumPicker extends StatelessWidget {
  final GalleryController controller;

  const AlbumPicker({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    return ValueListenableBuilder<Album?>(
      valueListenable: controller.album,
      builder: (context, album, _) => TextButton(
        onPressed: album == null ? null : () => _open(context),
        style: TextButton.styleFrom(
          foregroundColor: scope.theme.onSurface,
          minimumSize: const Size(0, PickerLayout.minButtonTouchHeight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                album == null ? scope.texts.gallery : _AlbumTile.nameOf(album, controller, scope),
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: scope.theme.onSurface, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.expand_more_rounded),
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final scope = PickerScope.of(context);
    final list = _AlbumList(controller: controller);
    final picked = PickerLayout.of(context).popups
        ? await showDialog<Album>(
            context: context,
            builder: (_) => scope.wrap(PickerPopup(color: scope.theme.background, child: list)),
          )
        : await showModalBottomSheet<Album>(
            context: context,
            backgroundColor: scope.theme.background,
            showDragHandle: true,
            isScrollControlled: true,
            builder: (_) => scope.wrap(list),
          );
    if (picked != null && picked != controller.album.value) await controller.switchAlbum(picked);
  }
}

class _AlbumList extends StatelessWidget {
  final GalleryController controller;

  const _AlbumList({required this.controller});

  @override
  Widget build(BuildContext context) {
    final albums = controller.albums.value;
    final scope = PickerScope.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
      child: ListView.separated(
        // a few albums make a short sheet or popup, not an empty tall one
        shrinkWrap: true,
        itemCount: albums.length,
        itemBuilder: (context, index) => _AlbumTile(album: albums[index], controller: controller),
        separatorBuilder: (context, index) =>
            Divider(color: scope.theme.onSurfaceMuted.withValues(alpha: 0.1), height: 0),
      ),
    );
  }
}

class _AlbumTile extends StatelessWidget {
  final Album album;
  final GalleryController controller;

  const _AlbumTile({required this.album, required this.controller});

  /// the first album is all items, its name differs by platform.
  static String nameOf(Album album, GalleryController controller, PickerScope scope) =>
      controller.albums.value.isNotEmpty && controller.albums.value.first == album
      ? scope.texts.recent
      : album.name;

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    final selected = album == controller.album.value;
    return ListTile(
      minTileHeight: 45,
      onTap: () => Navigator.of(context).pop(album),
      title: Text(
        nameOf(album, controller, scope),
        style: TextStyle(
          color: selected ? scope.theme.accent : scope.theme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Text(
        scope.texts.number(album.count),
        style: TextStyle(
          color: selected ? scope.theme.accent : scope.theme.onSurfaceMuted,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
