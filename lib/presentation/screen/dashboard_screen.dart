import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const new({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();

  static String get routeName => "/DashboardScreen";
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}
