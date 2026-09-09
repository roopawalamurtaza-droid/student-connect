import 'package:flutter/material.dart';

import '../models/campus_item.dart';
import '../repositories/campus_repository.dart';
import 'common.dart';

class PagedItems extends StatefulWidget {
  const PagedItems({
    super.key,
    required this.repository,
    required this.path,
    required this.builder,
  });
  final CampusRepository repository;
  final String path;
  final Widget Function(List<CampusItem>) builder;
  @override
  State<PagedItems> createState() => _PagedItemsState();
}

class _PagedItemsState extends State<PagedItems> {
  int offset = 0;
  @override
  void didUpdateWidget(PagedItems old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path) offset = 0;
  }

  @override
  Widget build(BuildContext context) {
    final uri = Uri.parse(widget.path);
    final path = widget.repository.isPreview
        ? widget.path
        : uri
              .replace(
                queryParameters: {
                  ...uri.queryParameters,
                  'limit': '30',
                  'offset': '$offset',
                },
              )
              .toString();
    return Items(
      repository: widget.repository,
      path: path,
      builder: (items) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          widget.builder(items),
          if (!widget.repository.isPreview &&
              (offset > 0 || items.length == 30))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                children: [
                  TextButton(
                    onPressed: offset == 0
                        ? null
                        : () => setState(() => offset -= 30),
                    child: const Text('Previous'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('Page ${offset ~/ 30 + 1}'),
                  ),
                  TextButton(
                    onPressed: items.length < 30
                        ? null
                        : () => setState(() => offset += 30),
                    child: const Text('Next'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
