import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/gallery/gallery_controller.dart';
import 'package:image_picker_plus/src/models/album.dart';

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
          minimumSize: const Size(0, PickerLayout.minTouch),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                album == null ? scope.texts.gallery : _AlbumTile.nameOf(album, controller, scope),
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scope.theme.onSurface),
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
    final picked = await showModalBottomSheet<Album>(
      context: context,
      backgroundColor: scope.theme.background,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => scope.wrap(_AlbumList(controller: controller)),
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
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: albums.length,
        itemBuilder: (context, index) => _AlbumTile(album: albums[index], controller: controller),
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
      onTap: () => Navigator.of(context).pop(album),
      title: Text(
        nameOf(album, controller, scope),
        style: TextStyle(color: selected ? scope.theme.accent : scope.theme.onSurface),
      ),
      trailing: Text(
        "${album.count}",
        style: TextStyle(
          color: selected ? scope.theme.accent : scope.theme.onSurfaceMuted,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
