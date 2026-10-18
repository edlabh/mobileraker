/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:flutter/material.dart';

import '../dto/get_vendor.dart';

/// Item de um fabricante nas listagens do Spoolman.
class VendorListEntry extends StatelessWidget {
  const VendorListEntry({super.key, required this.vendor, this.onTap});

  final GetVendor vendor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final comment = vendor.comment;
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.factory_outlined)),
      title: Text(vendor.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: (comment == null || comment.isEmpty)
          ? null
          : Text(comment, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: onTap,
    );
  }
}
