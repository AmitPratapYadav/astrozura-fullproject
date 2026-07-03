import 'package:flutter/material.dart';

import '../../../core/contants/api_constants.dart';
import '../../../core/models/app_content_catalog.dart';
import '../../../core/services/api_client.dart';
import '../../mainwidgets/header.dart';
import '../../shared/widgets/astrology_result_renderer.dart';

class LiveHoroscopeScreen extends StatefulWidget {
  final String initialSign;

  const LiveHoroscopeScreen({super.key, this.initialSign = 'aries'});

  @override
  State<LiveHoroscopeScreen> createState() => _LiveHoroscopeScreenState();
}

class _LiveHoroscopeScreenState extends State<LiveHoroscopeScreen> {
  final ApiClient _api = ApiClient();
  late String _sign;
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _sign = zodiacSigns.any(
      (sign) => sign.key == widget.initialSign.toLowerCase(),
    )
        ? widget.initialSign.toLowerCase()
        : 'aries';
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final response = await _api.get(ApiConstants.dailyHoroscope(_sign));
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (response['status'] == 'success') {
          _result = response;
        } else {
          _error =
              response['message']?.toString() ?? 'Horoscope is unavailable.';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const HeaderWidget(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.maybePop(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        ),
                        const Expanded(
                          child: Text(
                            'Daily Horoscope',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E3557),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 104,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: zodiacSigns.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final sign = zodiacSigns[index];
                          final selected = sign.key == _sign;
                          return InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              setState(() => _sign = sign.key);
                              _load();
                            },
                            child: Container(
                              width: 78,
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFFE8E6FF)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFF8B88E6)
                                      : const Color(0xFFE6E6E6),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Image.asset(
                                      sign.assetPath,
                                    ),
                                  ),
                                  Text(
                                    sign.name,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error != null)
                      _ErrorCard(message: _error!, onRetry: _load)
                    else if (_result != null)
                      AstrologyResultRenderer(response: _result!),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
