// ============================================================================
// legal_screen.dart  –  4 standalone legal screens + GDPR consent dialog
// Verantwortlicher: Moussahim Ammari – Emil-Warburg-Weg 19, 95447 Bayreuth
// ============================================================================
import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/theme.dart';

// --- Shared helper widgets ---------------------------------------------------

Widget _legalHeader(String title, IconData icon, String subtitle) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.14),
          AppColors.primary.withValues(alpha: 0.03),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.28)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                    fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _section(String title, String body,
    {String? linkUrl, String? linkLabel}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryGlow,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.75,
          ),
        ),
        if (linkUrl != null) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => launchUrl(Uri.parse(linkUrl),
                mode: LaunchMode.externalApplication),
            child: Text(
              linkLabel ?? linkUrl,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppColors.primary,
                height: 1.7,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.primary,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

Widget _infoCard(List<Widget> children) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.only(bottom: 20),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}

Widget _rowInfo(IconData icon, Color color, String label, String value) {
  // ignore: deprecated_member_use
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted)),
            const SizedBox(height: 2),
            Text(value,
                style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.5)),
          ],
        ),
      ),
    ],
  );
}

Widget _footer() {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 28),
    child: Center(
      child: Column(
        children: [
          Container(width: 40, height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Text(
            '\u00a9 2025\u20132026 Moussahim Ammari',
            style: GoogleFonts.outfit(
                fontSize: 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'ZapfNavi: Spritpreise \u2013 Alle Rechte vorbehalten',
            style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

AppBar _legalAppBar(BuildContext context, String title) {
  return AppBar(
    backgroundColor: AppColors.surface,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded,
          color: AppColors.textPrimary),
      onPressed: () => Navigator.pop(context),
    ),
    title: Text(
      title,
      style: GoogleFonts.outfit(
          fontWeight: FontWeight.w700,
          fontSize: 17,
          color: AppColors.textPrimary),
    ),
    centerTitle: true,
  );
}

// ============================================================================
// 1. IMPRESSUM
// ============================================================================
class ImpressumScreen extends StatelessWidget {
  const ImpressumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _legalAppBar(context, 'Impressum'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        children: [
          _legalHeader(
            'Impressum',
            Icons.business_rounded,
            'Pflichtangaben gem\u00e4\u00df \u00a7 5 TMG',
          ),
          const SizedBox(height: 24),
          _infoCard([
            _rowInfo(Icons.person_rounded, AppColors.primary, 'Name',
                'Moussahim Ammari'),
            const Divider(color: AppColors.divider, height: 20),
            _rowInfo(Icons.home_rounded, AppColors.primarySoft, 'Adresse',
                'Emil-Warburg-Weg 19\n95447 Bayreuth\nDeutschland'),
            const Divider(color: AppColors.divider, height: 20),
            _rowInfo(Icons.phone_android_rounded, AppColors.cheap, 'App',
                'ZapfNavi: Spritpreise\nBenzinpreis-Vergleich Deutschland'),
          ]),
          _section(
            '\u00a7 5 TMG \u2013 Angaben',
            'Gem\u00e4\u00df \u00a7 5 des Telemediengesetzes (TMG) ist als Diensteanbieter'
                ' folgende Person verantwortlich:\n\n'
                'Moussahim Ammari\n'
                'Emil-Warburg-Weg 19\n'
                '95447 Bayreuth\n'
                'Deutschland',
          ),
          _section(
            'Kontakt',
            'E-Mail: moussahimammari1234@gmail.com\n\n'
                'F\u00fcr Anfragen bez\u00fcglich der App, Datenschutz, Bugs oder'
                ' Kooperationen stehe ich per E-Mail zur Verf\u00fcgung.\n'
                'Antwortzeit: in der Regel innerhalb von 48 Stunden.',
            linkUrl: 'mailto:moussahimammari1234@gmail.com',
            linkLabel: '\ud83d\udce7 moussahimammari1234@gmail.com',
          ),
          _section(
            'Verantwortlich f\u00fcr den Inhalt (\u00a7 55 Abs. 2 RStV)',
            'Moussahim Ammari\n'
                'Emil-Warburg-Weg 19\n'
                '95447 Bayreuth\n'
                'Deutschland',
          ),
          _section(
            'Haftung f\u00fcr Inhalte',
            'Als Diensteanbieter bin ich gem\u00e4\u00df \u00a7 7 Abs. 1 TMG f\u00fcr eigene'
                ' Inhalte verantwortlich. Nach \u00a7\u00a7 8\u201310 TMG bin ich nicht'
                ' verpflichtet, \u00fcbermittelte oder gespeicherte fremde'
                ' Informationen zu \u00fcberwachen.',
          ),
          _section(
            'Haftung f\u00fcr Links',
            'Die App enth\u00e4lt Links zu externen Webseiten. F\u00fcr die Inhalte'
                ' verlinkter Seiten ist der jeweilige Anbieter verantwortlich.'
                ' Eine permanente Kontrolle der Inhalte ist ohne konkreten'
                ' Anhaltspunkt nicht zumutbar.',
          ),
          _section(
            'Urheberrecht',
            'Die in der App erstellten Inhalte unterliegen dem deutschen'
                ' Urheberrecht. Vervielf\u00e4ltigung, Bearbeitung und Verbreitung'
                ' au\u00dferhalb der Grenzen des Urheberrechts bed\u00fcrfen der'
                ' schriftlichen Zustimmung des Autors.',
          ),
          _section(
            'Plattform der EU-Kommission (OS)',
            'Gem\u00e4\u00df EU-Verordnung Nr. 524/2013 stellt die EU-Kommission eine'
                ' Online-Streitbeilegungs-Plattform (OS) bereit:',
            linkUrl: 'https://ec.europa.eu/consumers/odr',
            linkLabel: '\ud83c\udf10 ec.europa.eu/consumers/odr',
          ),
          _footer(),
        ],
      ),
    );
  }
}

// ============================================================================
// 2. DATENSCHUTZERKLAERUNG (DSGVO)
// ============================================================================
class DatenschutzScreen extends StatelessWidget {
  const DatenschutzScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _legalAppBar(context, 'Datenschutzerkl\u00e4rung'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        children: [
          _legalHeader(
            'Datenschutzerkl\u00e4rung',
            Icons.shield_rounded,
            'DSGVO-konforme Datenschutzinformationen \u00b7 Stand: Februar 2026',
          ),
          const SizedBox(height: 24),
          _infoCard([
            _rowInfo(Icons.person_rounded, AppColors.primary,
                'Verantwortlicher (Art. 13 DSGVO)', 'Moussahim Ammari'),
            const Divider(color: AppColors.divider, height: 20),
            _rowInfo(Icons.home_rounded, AppColors.primarySoft, 'Adresse',
                'Emil-Warburg-Weg 19\n95447 Bayreuth\nDeutschland'),
            const Divider(color: AppColors.divider, height: 20),
            _rowInfo(Icons.email_rounded, AppColors.cheap, 'E-Mail',
                'moussahimammari1234@gmail.com'),
          ]),
          _section(
            '1. \u00dcberblick der Datenverarbeitung',
            'Diese Datenschutzerkl\u00e4rung informiert Sie \u00fcber Art, Umfang und'
                ' Zweck der Verarbeitung personenbezogener Daten in der App'
                ' \u201eZapfNavi: Spritpreise\u201c (Android). Die Verarbeitung Ihrer Daten erfolgt'
                ' ausschlie\u00dflich im Rahmen der geltenden Datenschutzgesetze,'
                ' insbesondere der EU-DSGVO und des BDSG.',
          ),
          _section(
            '2. Standortdaten (GPS) \u2013 Art. 6 Abs. 1 lit. a DSGVO',
            'Die App nutzt Ihren GPS-Standort ausschlie\u00dflich zur Anzeige'
                ' nahegelegener Tankstellen. Standortdaten werden:\n\n'
                '\u2022 Nicht dauerhaft gespeichert\n'
                '\u2022 Nicht an unsere Server \u00fcbertragen\n'
                '\u2022 Nicht an Dritte weitergegeben\n'
                '\u2022 Nur zur Abfrage der Tankerk\u00f6nig-API genutzt (Radius-Suche)\n\n'
                'Rechtsgrundlage: Art. 6 Abs. 1 lit. a DSGVO (Einwilligung).\n'
                'Sie k\u00f6nnen den Standortzugriff jederzeit in den'
                ' Ger\u00e4teeinstellungen widerrufen.',
          ),
          _section(
            '3. Supabase \u2013 Backend & Authentifizierung',
            'F\u00fcr optionale Benutzerkonten nutzen wir Supabase (Supabase Inc.,'
                ' 970 Tresser Blvd, Stamford, CT, USA). Bei freiwilliger'
                ' Registrierung werden gespeichert:\n\n'
                '\u2022 E-Mail-Adresse (verschl\u00fcsselt)\n'
                '\u2022 Passwort (gehasht, nie im Klartext)\n'
                '\u2022 Favorisierte Tankstellen-IDs\n\n'
                'Supabase ist nach EU-US Data Privacy Framework zertifiziert.'
                ' Rechtsgrundlage: Art. 6 Abs. 1 lit. b DSGVO (Vertragserf\u00fcllung).',
            linkUrl: 'https://supabase.com/privacy',
            linkLabel:
                '\ud83d\udd17 Datenschutz Supabase: supabase.com/privacy',
          ),
          _section(
            '4. Tankerk\u00f6nig API \u2013 Kraftstoffpreise',
            'Kraftstoffpreisdaten werden \u00fcber die offizielle Tankerk\u00f6nig-API'
                ' des Bundeskartellamts (MTS-K) abgerufen. Dabei werden:\n\n'
                '\u2022 Nur der ungef\u00e4hre Suchstandort (\u00dcbermittlung von Koordinaten)\n'
                '\u2022 Keine personenbezogenen Daten an Tankerk\u00f6nig gesendet\n'
                '\u2022 Die Daten unter Creative-Commons-Lizenz CC BY 4.0 genutzt\n\n'
                'Tankerk\u00f6nig ist eine Open-Data-Initiative des Bundes.',
            linkUrl: 'https://www.tankerkoenig.de',
            linkLabel: '\ud83d\udd17 tankerkoenig.de',
          ),
          _section(
            '5. Lokale Datenspeicherung',
            'Einige Einstellungen werden ausschlie\u00dflich lokal auf Ihrem Ger\u00e4t'
                ' gespeichert (SharedPreferences / Android-Datenspeicher):\n\n'
                '\u2022 Kraftstoffpr\u00e4ferenz (E5/E10/Diesel)\n'
                '\u2022 Suchradius\n'
                '\u2022 Preisalarm-Einstellungen\n'
                '\u2022 Favoriten (lokal)\n'
                '\u2022 DSGVO-Einwilligung\n\n'
                'Diese Daten verlassen das Ger\u00e4t nicht.',
          ),
          _section(
            '6. Push-Benachrichtigungen',
            'Mit Ihrer Einwilligung sendet die App lokale Benachrichtigungen'
                ' (Preisalarme). Diese werden ausschlie\u00dflich lokal auf dem'
                ' Ger\u00e4t durch flutter_local_notifications erzeugt \u2013 keine'
                ' externen Push-Dienste werden verwendet.\n\n'
                'Rechtsgrundlage: Art. 6 Abs. 1 lit. a DSGVO.',
          ),
          _section(
            '7. Ihre Rechte (Art. 15\u201321 DSGVO)',
            'Sie haben folgende Datenschutzrechte:\n\n'
                '\u2022 Auskunftsrecht (Art. 15 DSGVO)\n'
                '\u2022 Recht auf Berichtigung (Art. 16 DSGVO)\n'
                '\u2022 Recht auf L\u00f6schung / \u201eRecht auf Vergessenwerden\u201c (Art. 17)\n'
                '\u2022 Recht auf Einschr\u00e4nkung der Verarbeitung (Art. 18)\n'
                '\u2022 Recht auf Daten\u00fcbertragbarkeit (Art. 20)\n'
                '\u2022 Widerspruchsrecht (Art. 21)\n\n'
                'Anfragen richten Sie an:\n'
                'moussahimammari1234@gmail.com\n\n'
                'Zust\u00e4ndige Datenschutz-Aufsichtsbeh\u00f6rde:\n\n'
                'Bayerisches Landesamt f\u00fcr Datenschutzaufsicht (BayLDA)\n'
                'Promenade 18, 91522 Ansbach\n'
                'www.lda.bayern.de',
            linkUrl: 'https://www.lda.bayern.de',
            linkLabel: '\ud83d\udd17 www.lda.bayern.de',
          ),
          _section(
            '8. Datensicherheit',
            'Wir setzen technische und organisatorische Sicherheitsma\u00dfnahmen ein:\n\n'
                '\u2022 Ausschlie\u00dflich verschl\u00fcsselte \u00dcbertragung (HTTPS/TLS)\n'
                '\u2022 Gehashte Passw\u00f6rter (bcrypt via Supabase)\n'
                '\u2022 Keine Speicherung sensibler Daten im Klartext\n'
                '\u2022 Regelm\u00e4\u00dfige Sicherheits\u00fcberpr\u00fcfungen',
          ),
          _section(
            '9. \u00c4nderungen dieser Datenschutzerkl\u00e4rung',
            'Diese Datenschutzerkl\u00e4rung kann bei Bedarf aktualisiert werden,'
                ' beispielsweise bei neuen Funktionen oder ge\u00e4nderten'
                ' gesetzlichen Anforderungen. Die aktuelle Version ist stets'
                ' in der App unter Einstellungen \u2192 Rechtliches verf\u00fcgbar.\n\n'
                'Letzte Aktualisierung: Februar 2026',
          ),
          _footer(),
        ],
      ),
    );
  }
}

// ============================================================================
// 4. DATENQUELLE & PREIS-HINWEISE
// ============================================================================
class DatenquelleScreen extends StatelessWidget {
  const DatenquelleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _legalAppBar(context, 'Datenquelle & Preis-Hinweise'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        children: [
          _legalHeader(
            'Datenquelle & Preis-Hinweise',
            Icons.source_rounded,
            'Herkunft der Kraftstoffpreise und rechtliche Hinweise',
          ),
          const SizedBox(height: 24),
          _infoCard([
            _rowInfo(
                Icons.verified_rounded,
                AppColors.cheap,
                'Offizielle Quelle',
                'Tankerk\u00f6nig API\nBundeskartellamt (MTS-K)'),
            const Divider(color: AppColors.divider, height: 20),
            _rowInfo(Icons.update_rounded, AppColors.primary, 'Aktualisierung',
                'Max. 5 Minuten Verz\u00f6gerung\n(gesetzl. Meldepflicht)'),
            const Divider(color: AppColors.divider, height: 20),
            _rowInfo(Icons.balance_rounded, AppColors.medium, 'Lizenz',
                'Creative Commons CC BY 4.0'),
          ]),
          _section(
            'Kraftstoffpreise \u2013 Tankerk\u00f6nig API',
            'Alle Kraftstoffpreise stammen von der offiziellen Tankerk\u00f6nig-API,'
                ' die von der Bundesnetzagentur / Bundeskartellamt im Rahmen der'
                ' Markttransparenzstelle f\u00fcr Kraftstoffe (MTS-K) bereitgestellt wird.\n\n'
                'Die Daten unterliegen der Creative-Commons-Lizenz CC BY 4.0.',
            linkUrl: 'https://www.tankerkoenig.de',
            linkLabel: '\ud83d\udd17 www.tankerkoenig.de',
          ),
          _section(
            'Aktualit\u00e4t der Preisdaten',
            'Tankstellen sind gesetzlich verpflichtet, Preis\u00e4nderungen'
                ' innerhalb von 5 Minuten an die MTS-K zu melden.\n\n'
                'Die App zeigt den Zeitstempel der letzten Aktualisierung'
                ' direkt auf der Detailseite jeder Tankstelle an.',
          ),
          _section(
            '\u26a0\ufe0f Keine Preisgarantie',
            'Die angezeigten Preise dienen als Orientierungshilfe.\n\n'
                'ZapfNavi: G\u00fcnstig Tanken gibt keine Garantie f\u00fcr Richtigkeit,'
                ' Vollst\u00e4ndigkeit oder Aktualit\u00e4t der Preisinformationen.'
                ' Vor dem Tanken empfehlen wir, den aktuellen Preis direkt'
                ' an der Tankstelle zu \u00fcberpr\u00fcfen.\n\n'
                'Moussahim Ammari haftet nicht f\u00fcr Sch\u00e4den, die durch'
                ' Preisungenauigkeiten oder tempor\u00e4re Datenausf\u00e4lle entstehen.',
          ),
          _section(
            'Kartenanbieter \u2013 OpenStreetMap',
            'Kartenansichten werden bereitgestellt von:\n\n'
                '\u00a9 OpenStreetMap-Mitwirkende\n'
                'Lizenz: Open Database License (ODbL)',
            linkUrl: 'https://www.openstreetmap.org/copyright',
            linkLabel: '\ud83d\udd17 OpenStreetMap Copyright',
          ),
          _section(
            'Open-Source-Bibliotheken',
            'Diese App verwendet folgende Open-Source-Bibliotheken:\n\n'
                '\u2022 Flutter SDK (BSD-Lizenz) \u2013 Google\n'
                '\u2022 flutter_map \u2013 BSD-Lizenz\n'
                '\u2022 fl_chart \u2013 MIT-Lizenz\n'
                '\u2022 Supabase Flutter \u2013 MIT-Lizenz\n'
                '\u2022 flutter_local_notifications \u2013 BSD-Lizenz\n'
                '\u2022 google_fonts \u2013 Apache 2.0\n'
                '\u2022 geolocator \u2013 MIT-Lizenz\n'
                '\u2022 provider \u2013 MIT-Lizenz\n'
                '\u2022 shared_preferences \u2013 BSD-Lizenz\n'
                '\u2022 http \u2013 BSD-Lizenz',
          ),
          _section(
            'App-Entwickler',
            'Moussahim Ammari\n'
                'Emil-Warburg-Weg 19\n'
                '95447 Bayreuth\n'
                'Deutschland\n\n'
                '\ud83d\udce7 moussahimammari1234@gmail.com\n'
                '\ud83d\udecd\ufe0f Google Play: ZapfNavi: G\u00fcnstig Tanken',
          ),
          _footer(),
        ],
      ),
    );
  }
}

// ============================================================================
// GDPR CONSENT DIALOG – shown on FIRST app launch
// ============================================================================
class GdprConsentDialog extends StatefulWidget {
  const GdprConsentDialog({super.key});

  static Future<bool> isConsentGiven() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('gdpr_consented') ?? false;
  }

  static Future<void> showIfNeeded(BuildContext context) async {
    final given = await isConsentGiven();
    if (given) return;
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const GdprConsentDialog(),
    );
  }

  @override
  State<GdprConsentDialog> createState() => _GdprConsentDialogState();
}

class _GdprConsentDialogState extends State<GdprConsentDialog> {
  bool _notifConsent = true;

  Future<void> _accept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('gdpr_consented', true);
    await prefs.setBool('gdpr_ads', true);
    await prefs.setBool('gdpr_notifications', _notifConsent);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.primary.withValues(alpha: 0.04),
                  ],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_rounded,
                        color: AppColors.primary, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Datenschutz & Einwilligung',
                    style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'ZapfNavi respektiert Ihre Privatsph\u00e4re.\nBitte w\u00e4hlen Sie Ihre Einstellungen.',
                    style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Verantwortlich: Moussahim Ammari, 95447 Bayreuth',
                    style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Consent Options
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _consentTile(
                      Icons.location_on_rounded,
                      AppColors.cheap,
                      'Standort (GPS)',
                      'F\u00fcr Tankstellensuche in Ihrer N\u00e4he (erforderlich)',
                      true,
                      null,
                    ),
                    const SizedBox(height: 10),
                    _consentTile(
                      Icons.notifications_rounded,
                      AppColors.primary,
                      'Push-Benachrichtigungen',
                      'Preisalarme wenn Kraftstoffpreis sinkt',
                      _notifConsent,
                      (v) => setState(() => _notifConsent = v),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _legalLink(
                            context, 'Datenschutz', const DatenschutzScreen()),
                        Text(' \u00b7 ',
                            style: GoogleFonts.outfit(
                                color: AppColors.textMuted, fontSize: 12)),
                        _legalLink(
                            context, 'Impressum', const ImpressumScreen()),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _accept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                    shadowColor: AppColors.primary.withValues(alpha: 0.4),
                  ),
                  child: Text(
                    'Einwilligen & Fortfahren',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _consentTile(IconData icon, Color color, String title, String subtitle,
      bool value, Function(bool)? onChanged) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value ? color.withValues(alpha: 0.35) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                Text(subtitle,
                    style: GoogleFonts.outfit(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          if (onChanged != null)
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: color,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('Erforderlich',
                  style: GoogleFonts.outfit(
                      fontSize: 10, fontWeight: FontWeight.w700, color: color)),
            ),
        ],
      ),
    );
  }

  Widget _legalLink(BuildContext context, String label, Widget screen) {
    return GestureDetector(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12,
          color: AppColors.primary,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.primary,
        ),
      ),
    );
  }
}

// Backward compatibility redirect
class LegalScreen extends StatelessWidget {
  final String tab;
  const LegalScreen({super.key, this.tab = 'impressum'});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Widget screen;
      switch (tab) {
        case 'datenschutz':
          screen = const DatenschutzScreen();
          break;
        case 'datenquelle':
          screen = const DatenquelleScreen();
          break;
        default:
          screen = const ImpressumScreen();
      }
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => screen));
    });
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
