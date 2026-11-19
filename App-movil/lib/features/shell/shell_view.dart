// Estructura común de la app con sesión: barra superior, sección activa y menú lateral deslizable.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_tokens.dart';
import '../home/home_view.dart';
import '../metrics/metrics_view.dart';
import '../notes/notes_view.dart';
import '../settings/settings_view.dart';
import '../terminal/terminal_view.dart';
import 'shell_viewmodel.dart';
import 'widgets/app_drawer.dart';
import 'widgets/app_top_bar.dart';

const _edgeDragWidth = 24.0;
const _flingVelocity = 365 / kDrawerWidth;

/// Muestra la sección de [ShellViewModel] y gestiona el menú: botón, arrastre desde el borde y
/// cierre.
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

  bool _edgeDragging = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dragUpdate(DragUpdateDetails details) {
    _controller.value += (details.primaryDelta ?? 0) / kDrawerWidth;
  }

  void _dragEnd(DragEndDetails details) {
    final velocity = (details.primaryVelocity ?? 0) / kDrawerWidth;
    if (velocity.abs() > _flingVelocity) {
      _controller.fling(velocity: velocity);
    } else if (_controller.value > 0.5) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _edgeDragEnd(DragEndDetails details) {
    setState(() => _edgeDragging = false);
    _dragEnd(details);
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
                  AppTopBar(title: vm.active.label, onIcon: _controller.forward),
                  Expanded(
                    child: switch (vm.active) {
                      Section.home => const HomeView(),
                      Section.metrics => const MetricsView(),
                      Section.notes => const NotesView(),
                      Section.terminal => const TerminalView(),
                      Section.settings => const SettingsView(),
                    },
                  ),
                ],
              ),
              if (!closed)
                FadeTransition(
                  key: const ValueKey('scrim'),
                  opacity: _scrimOpacity,
                  child: Semantics(
                    button: true,
                    label: 'Cerrar menú',
                    child: GestureDetector(
                      onTap: _controller.reverse,
                      onHorizontalDragUpdate: _dragUpdate,
                      onHorizontalDragEnd: _dragEnd,
                      child: Container(color: kScrim),
                    ),
                  ),
                ),
              if (!closed)
                Align(
                  key: const ValueKey('drawer'),
                  alignment: Alignment.centerLeft,
                  child: SlideTransition(
                    position: _slide,
                    child: GestureDetector(
                      onHorizontalDragUpdate: _dragUpdate,
                      onHorizontalDragEnd: _dragEnd,
                      child: AppDrawer(
                        active: vm.active,
                        paired: vm.isPaired,
                        onSelect: (s) => _select(vm, s),
                        onClose: _controller.reverse,
                      ),
                    ),
                  ),
                ),
              if (closed || _edgeDragging)
                Positioned(
                  key: const ValueKey('edge'),
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: _edgeDragWidth,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragStart: (_) => setState(() => _edgeDragging = true),
                    onHorizontalDragUpdate: _dragUpdate,
                    onHorizontalDragEnd: _edgeDragEnd,
                    onHorizontalDragCancel: () => setState(() => _edgeDragging = false),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
