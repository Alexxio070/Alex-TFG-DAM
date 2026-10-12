import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_tokens.dart';
import '../home/home_view.dart';
import '../metrics/metrics_view.dart';
import '../terminal/terminal_view.dart';
import 'shell_viewmodel.dart';
import 'widgets/app_drawer.dart';
import 'widgets/app_top_bar.dart';

const _scrim = Color.fromRGBO(22, 24, 29, 0.45);

class ShellView extends StatefulWidget {
  const ShellView({super.key});

  @override
  State<ShellView> createState() => _ShellViewState();
}

class _ShellViewState extends State<ShellView> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  )..addStatusListener((_) => setState(() {}));

  late final Animation<Offset> _slide = Tween(
    begin: const Offset(-1, 0),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: const Cubic(0.2, 0.8, 0.2, 1)));

  late final Animation<double> _scrimOpacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 240 / 280, curve: Curves.ease),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _select(ShellViewModel vm, Section section) {
    vm.select(section);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ShellViewModel>();
    final t = context.tokens;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final closed = _controller.isDismissed;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      ),
      child: PopScope(
        canPop: closed,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _controller.reverse();
        },
        child: Scaffold(
          backgroundColor: t.bg,
          body: Stack(
            children: [
              Column(
                children: [
                  AppTopBar(title: vm.active.label, onMenu: _controller.forward),
                  Expanded(
                    child: switch (vm.active) {
                      Section.home => const HomeView(),
                      Section.metrics => const MetricsView(),
                      Section.terminal => const TerminalScreen(),
                      _ => _SectionBody(section: vm.active),
                    },
                  ),
                ],
              ),
              if (!closed)
                FadeTransition(
                  opacity: _scrimOpacity,
                  child: Semantics(
                    button: true,
                    label: 'Cerrar menú',
                    child: GestureDetector(
                      onTap: _controller.reverse,
                      child: Container(color: _scrim),
                    ),
                  ),
                ),
              if (!closed)
                Align(
                  alignment: Alignment.centerLeft,
                  child: SlideTransition(
                    position: _slide,
                    child: AppDrawer(
                      active: vm.active,
                      paired: vm.isPaired,
                      onSelect: (s) => _select(vm, s),
                      onClose: _controller.reverse,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  const _SectionBody({required this.section});

  final Section section;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(section.label, style: TextStyle(color: context.tokens.muted)),
    );
  }
}
