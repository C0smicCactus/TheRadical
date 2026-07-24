import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/app_colors.dart';
import '../core/app_config.dart';
import 'dashboard_dialogs.dart';

class DashboardDrawer extends StatelessWidget {
  final Color primaryColor;
  final Function(Color) onThemeChanged;
  final bool extendedMode, hideTheory;
  final Function(bool) onExtendedModeChanged, onHideTheoryChanged;
  final String activeFilter;
  final Function(String) onFilterChanged;
  final VoidCallback onShowSources, onShowAbout;
  final VoidCallback onResetFeed;

  const DashboardDrawer({
    super.key, required this.primaryColor, required this.onThemeChanged, required this.extendedMode,
    required this.onExtendedModeChanged, required this.hideTheory, required this.onHideTheoryChanged,
    required this.activeFilter, required this.onFilterChanged, required this.onShowSources, required this.onShowAbout,
    required this.onResetFeed,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.appSurface,
      child: ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 60),
        Row(children: [FaIcon(FontAwesomeIcons.gear, color: primaryColor), const SizedBox(width: 12), const Text("CONTROL PANEL", style: TextStyle(fontWeight: FontWeight.bold))]),
        const SizedBox(height: 30),
        SwitchListTile(title: const Text("EXTENDED COVERAGE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), subtitle: const Text("Include broader independent sources.", style: TextStyle(fontSize: 10)), value: extendedMode, activeThumbColor: primaryColor, onChanged: onExtendedModeChanged),
        SwitchListTile(title: const Text("FILTER THEORY", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), subtitle: const Text("Hide book reviews and essays.", style: TextStyle(fontSize: 10)), value: hideTheory, activeThumbColor: primaryColor, onChanged: onHideTheoryChanged),
        const SizedBox(height: 40),
        const Text("THEME PALETTE", style: TextStyle(fontSize: 10, color: AppColors.textSubtle, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(spacing: 10, runSpacing: 10, children: [
          ...AppColors.themeChoices.map((c) => GestureDetector(
            onTap: () => onThemeChanged(c),
            child: Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: c,
                border: Border.all(color: primaryColor == c ? Colors.white : Colors.transparent, width: 2),
              ),
            ),
          )),
          GestureDetector(
            onTap: () => DashboardDialogs.showCustomColorDialog(
              context: context,
              currentColor: primaryColor,
              onColorSelected: onThemeChanged,
            ),
            child: Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5757), Color(0xFF57FFFF), Color(0xFF57FF57), Color(0xFFFF57FF), Color(0xFFFF5757)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white54, width: 2),
              ),
              child: const Icon(Icons.color_lens, color: Colors.white, size: 18),
            ),
          ),
        ]),
        const SizedBox(height: 40),
        const Text("TOPIC FILTERS", style: TextStyle(fontSize: 10, color: AppColors.textSubtle, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...["ALL", ...AppConfig.topics.map((t) => t.name)].map((n) => Padding(padding: const EdgeInsets.only(bottom: 8), child: SizedBox(width: double.infinity, child: TextButton(onPressed: () => onFilterChanged(n), style: TextButton.styleFrom(backgroundColor: activeFilter == n ? primaryColor : Colors.transparent, alignment: Alignment.centerLeft, side: BorderSide(color: activeFilter == n ? primaryColor : AppColors.borderSubtle)), child: Text(n, style: TextStyle(color: activeFilter == n ? Colors.black : Colors.white60, fontSize: 11, fontWeight: FontWeight.bold)))))),
        const SizedBox(height: 40),
        _btn("SIGNAL SOURCES", FontAwesomeIcons.satelliteDish, onShowSources),
        const SizedBox(height: 12),
        _btn("ABOUT PROJECT", FontAwesomeIcons.circleInfo, onShowAbout),
        const SizedBox(height: 30),
        _resetBtn(context),
      ]),
    );
  }

  Widget _resetBtn(BuildContext ctx) => InkWell(
    onTap: () {
      showDialog(
        context: ctx,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.appSurface,
          title: const Text("Reset Feed?", style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text("This will wipe all cached articles and viewed story tracking.\nYour settings (theme, filters, coverage) will be preserved.\n\nA fresh feed update will load immediately.", style: TextStyle(fontSize: 12)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: AppColors.textSubtle))),
            TextButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(ctx); onResetFeed(); }, child: const Text("RESET", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
          ],
        ),
      );
    },
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
        color: AppColors.highlightOverlay,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              FaIcon(FontAwesomeIcons.rotate, size: 14, color: Colors.red),
              SizedBox(width: 12),
              Text("RESET FEED", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.red)),
            ],
          ),
          FaIcon(FontAwesomeIcons.arrowRight, size: 10, color: Colors.red),
        ],
      ),
    ),
  );

  Widget _btn(String t, FaIconData i, VoidCallback o) => InkWell(onTap: o, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: primaryColor.withValues(alpha: 0.3)), color: AppColors.highlightOverlay), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [FaIcon(i, size: 14, color: primaryColor), const SizedBox(width: 12), Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2))]), FaIcon(FontAwesomeIcons.arrowRight, size: 10, color: primaryColor)])));
}