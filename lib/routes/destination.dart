import 'package:flutter/material.dart';

enum Destination {
  home('Home', Icons.space_dashboard_outlined),
  discover('Discover', Icons.explore_outlined),
  create('Create', Icons.add_circle_outline),
  events('Events', Icons.calendar_month_outlined),
  profile('Profile', Icons.person_outline);

  const Destination(this.label, this.icon);
  final String label;
  final IconData icon;
}
