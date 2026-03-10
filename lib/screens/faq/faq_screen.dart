import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const List<Map<String, String>> _faqs = [
    {
      'q': 'Wie findet die App die günstigsten Tankstellen?',
      'a':
          'Wir nutzen die offizielle Markttransparenzstelle für Kraftstoffe (MTS-K) über die Tankerkönig-API. Die Preise werden in Echtzeit aktualisiert und nach Preis oder Entfernung sortiert angezeigt.',
    },
    {
      'q': 'Wie oft werden die Preise aktualisiert?',
      'a':
          'Tankstellen in Deutschland müssen Preisänderungen innerhalb von 5 Minuten melden. Die App lädt bei jedem App-Start frische Daten. Du kannst auch manuell über das GPS-Symbol neu laden.',
    },
    {
      'q': 'Was ist der Preisalarm?',
      'a':
          'Der Preisalarm benachrichtigt dich, wenn der Kraftstoffpreis in deiner Nähe unter deinen eingestellten Schwellenwert fällt. Du kannst die Alarmschwelle in den Einstellungen anpassen.',
    },
    {
      'q': 'Was bedeutet „Favorit"?',
      'a':
          'Du kannst Tankstellen als Favoriten speichern. Diese erscheinen sowohl in der Favoritenliste und werden mit deinem Konto synchronisiert, falls du eingeloggt bist.',
    },
    {
      'q': 'Was ist der Routenplaner?',
      'a':
          'Der Routenplaner berechnet die Route zwischen zwei Orten und öffnet Google Maps für die Navigation. Du kannst dabei auch "Autobahn vermeiden" aktivieren.',
    },
    {
      'q': 'Was bedeutet „Top Deal"?',
      'a':
          'Top Deal markiert die günstigste Tankstelle in deinem Suchbereich. Sie wird ganz oben angezeigt und mit einer speziellen grünen Markierung hervorgehoben.',
    },
    {
      'q': 'Warum sehe ich keine Preise?',
      'a':
          'Manche Tankstellen melden keine Preise oder haben aktuell geschlossen. Überprüfe deine Internetverbindung, ändere den Kraftstofftyp oder vergrößere den Suchradius in der Suche.',
    },
    {
      'q': 'Wie erhalte ich Premium?',
      'a':
          'Premium kostet €7,99/Monat und entfernt alle Werbeanzeigen. Außerdem erhältst du erweiterte Preisalarme und Prioritätssupport. Upgrade über den Tab "Premium" unten in der App.',
    },
    {
      'q': 'Wie kann ich meine Daten löschen?',
      'a':
          'Du kannst dein Konto und alle zugehörigen Daten über Einstellungen → Konto löschen entfernen. Alternativ schreibe uns über Kontakt & Support.',
    },
    {
      'q': 'Welche Kraftstoffe werden angezeigt?',
      'a':
          'Aktuell unterstützen wir Diesel, Super E5 und Super E10. Diese decken die gängigsten Kraftstoffarten in Deutschland ab.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Häufige Fragen',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(18),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A1F0A), Color(0xFF0D2B1A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.help_outline_rounded,
                    color: AppColors.primary, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FAQ',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: AppColors.textPrimary)),
                      Text('Antworten auf häufig gestellte Fragen',
                          style: GoogleFonts.outfit(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // FAQ items
          ..._faqs
              .map((faq) => _FaqTile(question: faq['q']!, answer: faq['a']!)),
          const SizedBox(height: 20),
          Center(
            child: Text('Noch mehr Fragen? Schreib uns!',
                style: GoogleFonts.outfit(
                    fontSize: 13, color: AppColors.textMuted)),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/support'),
              icon: const Icon(Icons.mail_outline_rounded,
                  color: AppColors.primary, size: 18),
              label: Text('Kontakt & Support',
                  style: GoogleFonts.outfit(
                      color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;
  const _FaqTile({required this.question, required this.answer});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _expanded
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _expanded
                          ? AppColors.primaryGlow
                          : AppColors.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _expanded ? Icons.remove_rounded : Icons.add_rounded,
                      color:
                          _expanded ? AppColors.primary : AppColors.textMuted,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.question,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizeTransition(
              sizeFactor: _anim,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(54, 0, 14, 14),
                child: Text(
                  widget.answer,
                  style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
